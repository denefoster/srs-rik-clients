#----------------------------------------------------------------------------------------
# SRS::Client::Comms::XML
#----------------------------------------------------------------------------------------
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
#---------------------------------------------------------------------------------------

package SRS::Client::Comms::XML;

use strict;
use warnings;
use Carp;
use utf8;

use SRS::Client::URLEncoding;

use LWP::UserAgent;
use HTTP::Request::Common;

use constant DEFAULT_TIMEOUT => '180';

=head1 METHODS

=over 4

=cut

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    $args{url}       or croak "Missing parameter 'url'";
    $args{registrar} or croak "Missing parameter 'registrar'";
    $args{pgp}       or croak "Missing parameter 'pgp'";

    # prepend 'http' string, if it's not there
    if ($args{url} !~ /^http/) {
        $args{url} = 'http://' . $args{url};
    }

    if ($args{secureUrl}) {
        if ($args{secureUrl} !~ /^http/) {
            $args{secureUrl} = 'https://' . $args{secureUrl};
        }
    }
    else {
        $args{secureUrl} = $args{url};
        $args{secureUrl} =~ s|^http\:|https\:|;
        $args{secureUrl} =~ s|^(.+?)\:d+|$1|; # strip off port
    }

    # Create LWP UserAgent object
    my %ua_opt = (
        timeout => $args{timeout} || DEFAULT_TIMEOUT,
    );
    
    if ($LWP::UserAgent::VERSION >= 6) {
      if ($ENV{REGRESSION}){
        $ua_opt{ssl_opts} = { 
            verify_hostname => 0,
        };
      } else {
        $ua_opt{ssl_opts} = { 
            verify_hostname => 1,
            ($args{ca_file} ? (SSL_ca_file => $args{ca_file}) : ()),
            ($args{ca_path} ? (SSL_ca_path => $args{ca_path}) : (SSL_ca_path => '/etc/ssl/certs')),
        };
      }     
    }
    
    $args{ua} = LWP::UserAgent->new(%ua_opt);
    
    if ( $args{ua_string} ) {
        $args{ua}->agent($args{ua_string});
    }

    my $self = \%args;

    bless ($self,$class);
    return $self;
}



=item B<$sender-E<gt>send(request =E<gt> $request [, requiresSecurity =E<gt> 1]);>

Sends the XML request to the server. request is an XML string, requiresSecurity indicates whether
the request should be sent over a secure channel or not. Returns an SRS::Error if an error occured
(or undef if not) and the XML response string.

=cut
#----------------------------------------------------------------------------------------
# Send
# Input: (as a hash)
#        request - the string to send as a request
#        requiresSecurity - boolean value indicating whether the request should be sent securely
#                           or not
#        postParams - any parameters to add to the POST request.
#        requiresSignature - whether the response requires a signature. Defaults to false (!)
#                           and error will be returned if this is set to true, and 
#                           the signature is not found
# Output: a list containing an error (if one occured) and the response string.
#----------------------------------------------------------------------------------------

sub send {
    my $self = shift;
    my %params = @_;

    my %postParams;
    if ($params{postParams}) {
        %postParams = %{$params{postParams}};
    }

    my $pgp = $self->{pgp};

    # Check for parameters
    unless (defined($params{request})) {
        return "Missing request";
    }

    my $request = $params{request};

    # HTTP::Message 6.03+ silently rewrites \n to be \r\n which breaks signatures
    # that we've generated with \n's,
    $request =~ s/(?<!\r)\n/\r\n/g;
    
    # Sign Request
    my $signature;
    if ($params{signature}) {
        $signature = $params{signature};
    } else {
        my %sign_params = ( Data => $request );
        if (defined($ENV{SRS_RIK_PASSPHRASE})) {
            $sign_params{PassPhrase} = $ENV{SRS_RIK_PASSPHRASE};
        } elsif (defined($ENV{SRS_RIK_PASSPHRASE_FILE})) {
            my $pass_file = $ENV{SRS_RIK_PASSPHRASE_FILE};
            if (-f $pass_file) {
                if (open(IN, $pass_file)) {
                    $sign_params{PassPhrase} = <IN>;
                    chomp $sign_params{PassPhrase};
                    close IN;
                } else {
                    carp "Failed to open $pass_file for reading: $!";
                    return "Could not sign request (Failed to open $pass_file for reading: $!)";
                }
            } else {
                carp "Failed to open $pass_file for reading, it doesn't exist.";
                return "Could not sign request($pass_file doesn't exist)";
            }
        }

        $signature = $pgp->sign(%sign_params);
    }

    # Check for error in signing
    unless (defined($signature)) {
        return "Could not sign request";
    }

    # Construct POST request
    $postParams{n} = $self->{registrar};
    $postParams{r} = $request;
    $postParams{s} = $signature;

    # Choose the URL string
    my $url = $self->{secureUrl}; # Default to secure
    unless ($params{requiresSecurity}) {
        $url = $self->{url};
    }

    my $req = POST $url, \%postParams;
    
    if ( ! $req ) {
        ## I can't really imagine how this could happen
        return "Missing request object";
    }
    
    # Set a custom content type header, if requested 
    if (defined $params{contentType}) {
        $req->header('Content-Type' => $params{contentType}); 
    }
    
    # Send request, and grab response back.
    my $response_xml = '';
    my $full_response = '';
    my $leftover = '';
    my $received_sig;
    my ($r, $s, $cnt);
    my $response_callback = sub {
        my($data, $res, $protocol) = @_;
        $cnt++;

        if (!$r && !$s) {
            if ($data =~ /r=/) {  # Response start
                $r = 1;
                $data =~ s/^.*?r=//;
            } else {
                $full_response .= $data;
                return;
            }
        }

        if ($r) {
            my ($rs, $ss) = ("$leftover$data" =~ /^(.*?)(\&.*)?$/);
            if ($rs =~ /\%/) {
                ($rs, $leftover) = ($rs =~ /^(.*)(\%.*?)$/);
            } else {
                $leftover = '';
            }
            $response_xml .= $self->urlDecode($rs); 

            if ($ss) {
                $r = 0;
                $s = 1;

                $ss =~ s/^\&//;
                $data = $ss;
            }
        }

        if ($s) {
            $received_sig .= $data; 
        }
    };

    # Send request, and grab response back.
    my $res = $self->{ua}->request($req, $response_callback, 4096);

    if ($res->content) {
        # If we have something in the content, it must have been due to an error
        # LWP doesn't run the callback if an HTTP error status code is returned
        $response_callback->($res->content);   
    }
    
    $response_xml .= $self->urlDecode($leftover); 

    my %headers;
    my $h;
    foreach $h ($res->header_field_names) {
        if ($h =~ m/^X-/) {
            $headers{$h} = $res->header($h);
        }
    }
    # Check to see if the response contains anything.
    return "No response received from server"
      unless $res;

    return "Invalid response received from server (".$res->as_string.",$full_response)"
      unless $response_xml;
      
    if ($params{requiresSignature} && ! defined $received_sig) {
        return "Missing signature received from server(".$res->as_string.",$response_xml)";
    }

    if (defined($received_sig)) {
        $received_sig =~ s/^s=//;
        $received_sig
          or return "No signature from server";
        $received_sig = $self->urlDecode($received_sig); 
        $pgp->verify(Data      => "$response_xml",
                     Signature => $received_sig)
          or return "Invalid signature from server (
                        $response_xml,$received_sig,".$pgp->errstr.")";
    }

    return (undef,$response_xml, \%headers);
}

#---------------------------------------------------------------------------
# urlDecode
# Description: private function to convert a url escaped string to a normal one.
# Input: the string to be converted.
# Output: The converted string.
#---------------------------------------------------------------------------
sub urlDecode {
    my $self = shift;
    
    return SRS::Client::URLEncoding::decode($_[0]);
}

1;
