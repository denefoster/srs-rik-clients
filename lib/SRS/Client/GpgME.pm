# SRS Crypt::GpgME interface
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

package SRS::Client::GpgME;

use strict;
use warnings;

use Carp;

use IO::File;
use Crypt::GpgME;
use FindBin;

sub new {
    my ($class, %args) = @_;

    my $self = {
        'ctx'        => Crypt::GpgME->new(),
        'public_key' => $args{'publicKeyRing'}
    };
    
    $self->{'ctx'}->set_passphrase_cb(sub { $args{'passphrase'} });

    $self->{'ctx'}->signers_add( $args{'secretKeyRing'} ) if defined $args{'secretKeyRing'};

    bless $self, $class;

    return $self;

}

sub verify {
    my ($self, %params) = @_;
    
    print "Sign: Primary Key - $FindBin::Bin/../etc/reg.key\n";
    
    print "Sign: Data - $params{'Data'}\n";

    my $verified = $self->{'ctx'}->verify( "$FindBin::Bin/../etc/reg.key", $params{'Data'} );

    return $verified;

}

sub sign {
    my ($self, %params) = @_;
    
    print "Verify: Data - $params{'Data'}\n";

    my $signed = $self->{'ctx'}->sign( $params{'Data'} );

    return $signed;

}

1;

__END__
