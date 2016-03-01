#---------------------------------------------------------------------------
# SRS::Client::URLEncoding
#------------------------------------------------------------------------------
#
# Copyright 2002-2012 NZ Registry Services
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
#---------------------------------------------------------------------------
package SRS::Client::URLEncoding;

# Encodes/decodes a string for the response to the client.

use strict;
use warnings;

use Encode qw();

# URL encode a whole string, possibly allowing multibyte chars.  This
# function assumes that we're either in a C-type locale, or the input
# strings are UTF-8.  Another co-incidence is that there are no valid
# multi-byte encodings in UTF-8 which involve bytes which we don't
# want to escape, or if they did then we wouldn't need to escape them.
sub encode {
    my $string = shift;
    defined($string) or return '';
    
    $string = Encode::encode('utf-8', $string);  # convert to bytes
    $string =~ s/([^0-9A-Za-z_\- ])/sprintf("%%%.2x", ord($1))/eg;
    $string =~ s/ /+/g;
    
    return $string;
}

# convert a url escaped string to a normal one.
sub decode {   
    return '' unless defined $_[0];

    $_[0] =~ tr/+/ /;
    $_[0] =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C",hex($1))/eg;
    return $_[0];
}

1;