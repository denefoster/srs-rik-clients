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

package SRS::Client::Options;

use strict;
use warnings;

use Getopt::Long qw(GetOptionsFromArray);
use JSON::Any qw(XS);
use File::Slurp qw(read_file write_file);

sub new {
    my ($class) = @_;

    my $self = {};
    bless ( $self, $class );
    return $self;
}

sub getOptions {
    my ($self,$args) = @_;

    my $config = $self->readConfig("$ENV{HOME}/.rikrc");
    my $commandline = $self->readCommandline($args);
    my $env = $self->readEnvironment();
    my $options = { %$config, %$env, %$commandline };

    return $options;
}

sub readConfig {
    my ($self,$file) = @_;

    # Create a now config file (if there isn't one already)
    if ( ! -f $file ) {
        my $j = JSON::Any->new(pretty => 1);
        my $defaults = {
            registrar_id => 999,
            debug => 0,
            timeout => 180,
            url => "srstest.srs.net.nz/srs/registrar",
        };
        write_file( $file, $j->encode($defaults) );
    }

    # Read the config file into a hash
    my $json = read_file($file);
    my $j = JSON::Any->new();
    return $j->decode($json);
}

sub readEnvironment {
    my ($self) = @_;

    my $options = {};
    my $vars = {
        SRS_URL => "url",
        SRS_REGISTRAR => "registrar_id",
        DEBUG => "debug",
        GNUPGID => "gpg_id",
        SRS_RIK_PASSPHRASE => "gpg_passphrase",
        SRS_RIK_PASSPHRASE_FILE => "gpg_passphrase_file",
    };
    for my $var ( keys %$vars ) {
        if ( $ENV{$var} ) {
            $options->{$vars->{$var}} = $ENV{$var};
        }
    }

    return $options;
}

sub configureGetopt {
    # We are normally happy with the defaults
}

sub defineCommandline {
    my ($self) = @_;

    return (
        'registrar_id|r=i',
        'file|f=s',
        'debug|d',
        'help|h',
        'url=s',
        'timeout|t=i',
        'gpg_id=s',
        'gpg_secret=s',
        'gpg_public=s',
        'gpg_passphrase=s',
        'gpg_passphrase_file=s',
    );
}

sub readCommandline {
    my ($self,$args) = @_;

    $self->configureGetopt();

    my $options = {};
    GetOptionsFromArray($args, $options, 
        $self->defineCommandline()
    );

    return $options;
}

1;
