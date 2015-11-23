# SRS Client::Crypt::OpenPGP interface
#
#--------------------------------------------------------------------------------------------------
#
# Copyright 2002-2004 NZ Registry Services
#
# This file is part of the Shared Registry System
#
# The Shared Registry System is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# The Shared Registry System is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the Shared Registry System; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#--------------------------------------------------------------------------------------------------

# This module is a wrapper around Crypt::OpenPGP. Other than the constructor,
#  (and the methods we consider 'private'), we take extra care not to throw
#  exceptions for any of our methods. All methods indicate errors by returning
#  false/undef. The errstr method can then be used to get the details of the error.

package SRS::Client::Crypt::OpenPGP;

use strict;
use warnings;
use Carp;

use Crypt::OpenPGP;
use Encode;
use Encoding::FixLatin qw(fix_latin);
use utf8;
use Time::HiRes qw(time);
use Data::Dumper;


sub new {
# Description: constructor; sets the keyring (file) and extarcts default key from it
# Input:  hash
#    secretKeyRing => file path or Crypt::OpenPGP::KeyRing object,
#    publicKeyRing => file path or Crypt::OpenPGP::KeyRing object,
#    uid           => key identifier (optional, default key taken from the ring)
# Output: Class object
#-------------------------------------------------------------------------
    my ($class, %args) = @_;

    # Create PGP Object
    my $pgp = new Crypt::OpenPGP( SecRing => $args{secretKeyRing},
                                  PubRing => $args{publicKeyRing},)
      or croak "
Cannot instantiate OpenPGP object for
  public key ring: $args{publicKeyRing}
  secret key ring: $args{secretKeyRing}
" . Crypt::OpenPGP->errstr;

    my $self = {PGP => $pgp};
    bless ($self,$class);

    my $uid = $args{uid} || "";
    $self->{DefaultSigningKey}    = $self->findSigningKey($uid)
      or warn "No default signing key $uid";
    $self->{DefaultEncryptingKey} = $self->findEncryptingKey($uid)
      or warn "No default encrypting key $uid";

    return $self;
}

our %keyblock_cache;

sub verify {
    my $self = shift;
    
    my $ret = eval {
        $self->_verify_impl(@_);
    };
    if ($@) {
        $self->{errstr} = $@;
        return undef;
    }
    
    return $ret;        
}

sub _verify_impl {
    my $self = shift;
    delete $self->{errstr};
    my %params = @_;

    my $data      = $params{Data}      or croak "Data not supplied";
    my $armoured_sig = $params{Signature} or croak "Signature not supplied";
    my $keytext   = $params{KeyText};
    my $keys      = $params{Keys};
    my $cert      = $params{Key};
    my $pgp = $self->{PGP};
    
    # unpack the signature
    my $msg = Crypt::OpenPGP::Message->new(Data => $armoured_sig)
        or die "reading data packets failed: " .Crypt::OpenPGP::Message->errstr;

    my @pieces = $msg->pieces;
	
	# this disallows non-detached signatures
	die "signature message contains multiple parts\n" if @pieces > 1;

	if ( ref($pieces[0]) ne 'Crypt::OpenPGP::Signature' ) {
        die "signature message is type '".ref($pieces[0])."', which is weird - rejecting\n";
	}
	
	my $signature = $pieces[0];

	die "Couldn't unpack signature\n" unless $signature;

    my $sig_key = eval { $signature->key_id };
    if ( !$sig_key ) {
	    $self->{errstr} = "signature did not contain a key_id subpacket";
	    return undef;
    }

    if ( !$cert ) {
	    my @keys = $keys ? @$keys : ($keytext ? ($keytext) : ());
	    my %keyring;
	    for my $key ( @keys ) {
		    my $keyblock;
		    if ( !($keyblock=$keyblock_cache{$key}) ) {
			    $keyblock = Crypt::OpenPGP::KeyBlock->new;
			    my $message = Crypt::OpenPGP::Message->new
				    ( Data => $key )
					    or croak "a key failed to unpack";
			    for my $packet ( $message->pieces ) {
				    $keyblock->add($packet);
			    }

			    $keyblock_cache{$key} = $keyblock;
		    }

		    # these aren't part of the documented API and
		    # appear to have been cargo culted from
		    # Crypt::OpenPGP::sign
		    my $cert = $keyblock->signing_key
			or croak "a key has no signing sub-key";
		    $cert->uid($keyblock->primary_uid);

		    my $keyid = $cert->key_id;
		    my $len = length $sig_key;
		    my $short_keyid = substr($keyid, -$len, $len);
                    # in some pathological siutations, eg keys sharing a keyid
		    # or subset of keyid that is the same as input keyid this
		    # could fail where it shouldn't.  normally though this is
		    # is a full 8 byte / 16-hex-digit keyid.
		    $keyring{$short_keyid} = $cert;
	    }
	if (@keys) {
	    ($cert) = $keyring{$sig_key};
	    if ( !$cert ) {
		    $self->{errstr} = "signing key ".unpack("H*",$sig_key)
			    ." not in keyring (extant: ".join(", ", map { unpack("H*", $_) } keys %keyring).")";
		    return undef;
	    }
	}
    }

    my $sig_ok = 0;
    my $pgp_errstr = "";
    my $res = $pgp->verify(Data      => utf8_encode($data),
                           Signature => $armoured_sig,
			   ($cert ? (Key       => $cert) : ()) );

    #warn $pgp->errstr if !$res && $pgp->errstr;
    if ( $res ) {
	    my $negative = $pgp->verify(
		    Data => "dummy".$$.time,
		    Signature => $armoured_sig,
		    Key => $cert,
		   );
	    if ( $res and $negative ) {
		    $res = undef;
		    $self->{errstr} = "signature valid on random input";
	    }
    }
    return $res;
}

sub sign {
    my $self = shift;
    delete $self->{errstr};
    my %params = @_;

    my $signature;

    eval {
        my $data       = $params{Data}       or croak "Data not supplied";
        my $key        = $params{Key}        || $self->{DefaultSigningKey};
        my $passphrase = $params{PassPhrase} || $params{Passphrase} || '';
        my $pgp        = $self->{PGP};
        print "PRESIGN\n";
        $signature = $pgp->sign(Data       => utf8_encode ($data),
                                Detach     => 1,
                                Armour     => 1,
                                Digest     => 'SHA1',
                                Passphrase => $passphrase,
                                Key        => $key);
        die "Signing attempt failed: ", $pgp->errstr() unless $signature;

    };
    if ($@) {
       $self->{errstr} = $@;
       return undef;
    }

    return $signature;
}

# Check a key text to see if it's a valid key
# Note, as this is a class method, we don't do the same checks for exceptions here
#  (as the caller can't call the errstr method later on, since they don't have an
#  instance). We just rely on the caller to trap exceptions.
sub checkKeyText {
    my $keytext = shift;
    my $cert;

    if ($keytext) {
        my $kr = new Crypt::OpenPGP::KeyRing(Data => $keytext)
          or return;
        my $kb = $kr->find_keyblock_by_index(-1)
          or return;
        $cert = $kb->signing_key
          or return;
        $cert->uid($kb->primary_uid);
    }

    return $cert;
}

sub errstr {
    my $self = shift;
    return $self->{errstr} || $self->{PGP}->errstr;
}

# ------------------
# Methods below this line are not used externally, so can probably be considered private (even though there's
#  nothing to indicate that they are). It's possible someone in registrar land is using them directly, though.
# We don't take the same care not to throw exceptions with these methods.

sub findSigningKey {
    my $self = shift;
    my $pgp = $self->{PGP};

    my $kb = $self->getSecKeyBlock(@_) or return;

    my $cert = $kb->signing_key
      or croak "Invalid signing key";
    $cert->uid($kb->primary_uid);
    return $cert;
}

sub findEncryptingKey {
    my $self = shift;
    my $pgp = $self->{PGP};
    
    my $kb = $self->getSecKeyBlock(@_) or return;

    my $cert = $kb->encrypting_key
      or croak "Invalid encrypting key";
    $cert->uid($kb->primary_uid);
    return $cert;
}

sub getSecKeyBlock {
    my $self = shift;
    my $uid = shift;
    my $pgp = $self->{PGP};

    my $sec_ring = $pgp->{cfg}->get('SecRing')
      or return;
      
    print "Sec Ring: $sec_ring\n";

    my $ring;
    if (ref $sec_ring && $sec_ring->isa('Crypt::OpenPGP::KeyRing' )) { # is blessed into Crypt::OpenPGP::KeyRing?
        $ring = $sec_ring
    } else {
        -f $sec_ring
          or croak "No secret ring <$sec_ring>";

        $ring = Crypt::OpenPGP::KeyRing->new( Filename => $sec_ring )
          or croak "Secret ring <$sec_ring> read error: ".Crypt::OpenPGP::KeyRing->errstr;
    }

    my $kb;
    if ($uid) {
      if ($uid =~ /^0x([0-9a-fA-F]{8})/) {
        $kb = $ring->find_keyblock_by_keyid(pack 'H*', $1);
      } else {
        $kb = $ring->find_keyblock_by_uid($uid);
      }
    } else {
      $kb = $ring->find_keyblock_by_index(-1);
    }

    croak "Can't find keyblock (".($uid ? $uid : "default")."): " . ($ring->errstr || 'no error string?!')
      unless defined $kb;

    return $kb;
}

sub getPubKeyBlock {
    my $self = shift;
    my $uid = shift;
    my $pgp = $self->{PGP};

    my $pub_ring = $pgp->{cfg}->get('PubRing')
      or return;

    my $ring;
    if (UNIVERSAL::isa( $pub_ring, 'Crypt::OpenPGP::KeyRing' )) { # is blessed into Crypt::OpenPGP::KeyRing?
        $ring = $pub_ring
    } else {
        -f $pub_ring
          or croak "No public ring <$pub_ring>";

        $ring = Crypt::OpenPGP::KeyRing->new( Filename => $pub_ring )
          or croak Crypt::OpenPGP::KeyRing->errstr;
    }

    my $kb = $uid ? $ring->find_keyblock_by_uid($uid)
                  : $ring->find_keyblock_by_index(-1)
      or croak "Can't find keyblock (".($uid ? $uid : "default")."): " . $ring->errstr;

    return $kb;
}

# Encode a string to UTF-8, but only if it isn't already UTF-8.
sub utf8_encode {
    my $str = shift;
    $str = fix_latin($str);
    if ($str =~ /(\\x\{\w+\})|[^\x00-\x7F]/){
        $str = encode("utf8", $str);
    }

    return $str;
}

1;
