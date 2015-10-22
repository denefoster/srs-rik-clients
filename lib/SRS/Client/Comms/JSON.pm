#----------------------------------------------------------------------------------------
# SRS::Client::Comms::JSON
# Communications client when using internal language
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
package SRS::Client::Comms::JSON;

use strict;
use warnings;


use base qw(SRS::Client::Comms::XML);


use LWP::UserAgent;
use HTTP::Request;
use Encode;

sub new {
    my $self = shift;
    my %params = @_;

    # Set pgp param to something so parent doesn't throw an exception
    $params{pgp} //= {};

    return $self->SUPER::new(%params);
}

sub send {
    my $self = shift;
    my $request = shift;

    my $url = $self->{secureUrl} . '/' . $self->{registrar};

    $request = Encode::encode('utf-8', $request) if utf8::is_utf8($request);

    my $req = HTTP::Request->new( 'POST', $url, ['Content-Type' => 'application/json'], $request );

    my $resp = $self->{ua}->request( $req );

    my $response = $resp->content;

    $response = Encode::decode('utf-8', $response) if ! utf8::is_utf8($response);

    return $response;
}


1;
