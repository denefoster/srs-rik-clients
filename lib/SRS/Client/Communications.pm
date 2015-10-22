#------------------------------------------------------------------------------
# Copyright 2002-2011 NZ Registry Services
#
# This file is part of the SRS Registrar Kit
#
# The SRS Registrar Kit is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# The SRS Registrar Kit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the SRS Registrar Kit; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#------------------------------------------------------------------------------

package SRS::Client::Communications;

use strict;
use warnings;
use Carp;
use Config;

#use SRS::Client::OpenPGP;
use SRS::Client::GpgME;
use SRS::Client::Versions;
use base qw (SRS::Client::Comms::XML);

=head1 NAME

SRS::Client::Communications

=head1 SYNOPSIS

 use SRS::Client::Communications;
 my $send = new SRS::Client::Communications (
                url => $url,
                registrar => $reg_no,
                uid => $uid,
                logPrefix => 'MyAppName'
                );

 my ($error,$response) = $send->send($requestdata);

 if ($error) {
    # handle error through SRS::Error interface
 }

=head1 DESCRIPTION

The Client Communication Execution Module (CCEM). This module connects to the specified URL and sends
an HTTP POST request, containing the registrar number, the request string and a digitial signature of
the request. The request string should be an XML document, as described in the SRS protocol
specification.

=head1 DEPENDENCIES

This module depends on the following modules, available from CPAN:

=over 4

=item *

Crypt::OpenPGP

=item *

LWP::UserAgent

=item *

HTTP::Request::Common

=back

The module SRS::Error is also used. This is a part of the SRS::Client distribution.

=head1 CONSTRUCTOR

=over 4

=item B<$sender = new SRS::Client::Communcations (
                    url       =E<gt> $url,
                    registrar =E<gt> $reg_no,
                    uid       =E<gt> $uid,
                    timeout   =E<gt> $timeout
                    pgp       =E<gt> $pgp
                );>

Creates an instance of the SRS::Client::Communications class. The parameters are:

=over 4

=item url

The address to connect to (the 'http://' or 'https://' prefix is optional, and will be overridden by
the 'requiresSecurity' parameter of the send() method).

=item registrar

The registrar ID of the registrar making the request

=item uid

The user ID string of the private key to use in signing the request.

=item timeout

The timeout value in seconds, for connecting to the server.

=item pgp

SRS::OpenPGP object (optional, one will be created if missing)

=back

=back

=cut

sub new(%)
{
    my ($proto, %args) = @_;
    $args{pgp} ||= new SRS::Client::GpgME;
    
    # If the program name was defined, build a UA string
    if ($args{program}) {
        my %versions = SRS::Client::Versions::get_versions();
        
        my $ua = $args{program} . "/" . ($versions{rik_version} || '???');
        $ua .= ' (';
        
        $ua .= ' CPAN libs version: '  . $versions{cpan_libs_version}  . '; ' if $versions{cpan_libs_version};
        $ua .= ' CPAN libs platform: ' . $versions{cpan_libs_platform} . '; ' if $versions{cpan_libs_platform};
        
        $ua .= ' archname: ' . $Config{archname} . '; ';
        
        $ua .= ')';
        $args{ua_string} = $ua;
    }

    return SRS::Client::Comms::XML->new(%args);
}

=head1 METHODS

=over 4

=cut

#---------------------------------------------------------------------------------------------

=item B<$sender-E<gt>send(request =E<gt> $request [, requiresSecurity =E<gt> 1]);>

Sends the XML request to the server. request is an XML string, requiresSecurity
indicates whether the request should be sent over a secure channel or not.
Returns an SRS::Error if an error occured (or undef if not) and the XML
response string.

=cut

#---------------------------------------------------------------------------

1;

=back

=cut
