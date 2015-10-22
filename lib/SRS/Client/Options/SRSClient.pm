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

package SRS::Client::Options::SRSClient;

use strict;
use warnings;

use Getopt::Long;

use base ('SRS::Client::Options');

sub configureGetopt {
    my ($self) = @_;

   Getopt::Long::Configure ("bundling_override");
}

sub defineCommandline {
    my ($self) = @_;

    my $synonyms = {
        'kS' => 'gpg_secret',
        'kP' => 'gpg_public',
        'u'  => 'gpg_id',
        'a'  => 'url',
    };

    my @definitions = $self->SUPER::defineCommandline();
    for my $def ( @definitions ) {
        for my $synonym ( keys %$synonyms ) {
            my $target = $synonyms->{$synonym};
            $def =~ s/$target/$target|$synonym/;
        }
    }

    return (
        @definitions
    );
}

sub readCommandline {
    my ($self,$args) = @_;

    # Somewhat complicated fudging here: 
       # move @$args to @temp    
       # empty @$args
       # copy MOST of @temp back into @$args
    # This is all so we can mess with the value of $args, which is passed in as a ref
    my @temp = @$args;
    splice @$args, 0, scalar(@$args);

    for my $i ( 0 .. scalar(@temp)-1 ) {
        # Need to remove the 'on' part of '-d on'
        my $prev = $i ? $i-1 : $i;
        if ( $temp[$prev] eq "-d" ) {
            if ( $temp[$i] =~ m/^on|off$/ ) {
                next;
            }
        }

        # Need to remove the arguments that are totally deprecated
        if ( $temp[$i] eq "-aS" ) {
            next;
        }
        if ( $temp[$i] eq "-e" ) {
            next;
        }

        push @$args, $temp[$i];
    }

    return $self->SUPER::readCommandline($args);
}

1;
