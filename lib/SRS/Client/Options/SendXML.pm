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

package SRS::Client::Options::SendXML;

use strict;
use warnings;

use base ('SRS::Client::Options');

sub defineCommandline {
    my ($self) = @_;

    return (
        $self->SUPER::defineCommandline(),
        'sub_actionid|s=s',
    );
}

sub readCommandline {
    my ($self,$args) = @_;

    my $options = $self->SUPER::readCommandline($args);

    # If the user hasn't specified a file option, but there is still 
    # one parameter left on commanline, it might be the file
    if ( ! $options->{file} ) {
        if ( scalar @$args == 1 ) {
            $options->{file} = $args->[0];
        }
    }

    return $options;
}
1;
