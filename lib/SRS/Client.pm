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
package SRS::Client;

use strict;
use warnings;

use File::Slurp qw(read_file);
use Time::HiRes qw (gettimeofday);
use Pod::Usage;
use FindBin;

use SRS::Client::Communications;
use SRS::Client::GpgME;
use SRS::Client::Versions;

sub error {
    my ($self,$error) = @_;
    
    pod2usage(
        -msg => $error,
        -exitval => 2,
    );
}

sub processCommandline {
    my ($self) = @_;

    if ( $self->{help} ) {
        pod2usage(
            -verbose => 2,
            -exitval => 0,
            -noperldoc => 1,
        );
    }

    for my $required ( "registrar_id", "file", "url" ) {
        if ( ! $self->{$required} ) {
            $self->error("Required option missing: $required");
        }
    }
}

sub checkCpanLibs {
    my ($self) = @_;

    if ( !SRS::Client::Versions::check_versions() ) {
        my %versions = SRS::Client::Versions::get_versions();
        die "RIK and CPAN libs versions differ. Cannot continue. RIK version: " .
            $versions{rik_version} . "; CPAN libs version: " . 
            $versions{cpan_libs_version} . "\n";
    }
}

sub sendXML {
    my ($self,$xml,$program) = @_;

    my $comms = SRS::Client::Communications->new(
        registrar => $self->{registrar_id},
        url => $self->{url},
        pgp => SRS::Client::GpgME->new(
            secretKeyRing => $self->{gpg_secret},
            publicKeyRing => $self->{gpg_public},
            passphrase    => $self->{gpg_passphrase},
            uid           => $self->{gpg_id},
        ),
#        pgp => new SRS::Client::OpenPGP(
#            secretKeyRing => $self->{gpg_secret},
#            publicKeyRing => $self->{gpg_public},
#            uid           => $self->{gpg_id},
#        ),
        timeout => $self->{timeout},
        secureUrl => $self->{url},    
        program => $program,
        ca_path => '/etc/ssl/certs',
    );

    my ($error, $response) = $comms->send(
        request => $xml,
        requiresSecurity => 1,
    );

    return ($error,$response);
}

1;

__END__

=head1 NAME

SRS::Client - base class for the RIK clients

=head1 DESCRIPTION

This module encapsulates the functionality of the SRS RIK command-line
clients (see those script's documentation for more details).

=head1 METHODS

=head2 error($error)

Displays $error, prints usage information, and exits. Called
when various error conditions are detected.

=cut

