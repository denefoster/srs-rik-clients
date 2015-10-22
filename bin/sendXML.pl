#!/usr/bin/perl
#--------------------------------------------------------------------------------------------------
#
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
#-----------------------------------------------------------------------------------------------------

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use SRS::Client::XML;

my $client = SRS::Client::XML->new(@ARGV);
print $client->run();

1;

__END__

=head1 NAME

sendXML - an SRS command-line client that accepts input and displays output as XML

=head1 SYNOPSIS

sendXML [options]

  Options:
    --registrar_id   -r   (required) id of the registrar to send requests as
    --file           -f   location of the file containing the request
    --debug          -d   display XML request and response       
    --url                 The URL of the srs system
    --timeout        -t   time the client should wait for the server
    --gpg_id              The GPG id that should sign the request
    --gpg_public          The path to the GPG public keyring file
    --gpg_secret          The path to the GPG secret keyring file
    --gpg_passphrase      The passphrase required to unlock the GPG key
    --gpg_passphrase_file File which contains the gpg_passphrase
    --sub_actionid   -s   Substitude the actionId attribute for a timestamp
    --help           -h   display documentation

=head1 OPTIONS

Options may be either specified directly on the command line, or from a 
configuration file (".rikrc" in the users home directory).

When the same option is specified using both methods, the command-line takes
precedence.  Additionally some options are synonymous with environment
variables, but the command-line still takes precedence - and you shouldn't set
the environment variables as that method is deprecated and may be removed in a 
future release.

=over 8

=item B<-r --registrar_id>

Specifies the ID of the registrar to send requests as

=item B<-f --file>

The file containing the request to be signed and sent to the SRS.

=item B<-d --debug>

Print the request and response XML to STDOUT.

=item B<--url>

The URL of the SRS system which you would like to communicate with.

=item B<-t --timeout>

The timeout, in seconds, of the communications with the SRS system.

=item B<--gpg_id>

Defines which GNUPG Id to use to sign the SRS request.

=item B<--gpg_public>

Specifies the path to the public keyring containing the public key used for
signing requests.  This will normally be a pubring.gpg file, when using GnuPG.

=item B<--gpg_secret>

Specifies the path to the private keyring containing the public key used for
signing requests.  This will normally be a secring.gpg file, when using GnuPG.

=item B<--gpg_passphrase>

Specifies the passphrase that will be used to unlock the PGP (or GPG) key
used for signing requests.

=item B<--gpg_passphrase_file>

Specifies the path to the file which contains passphrase that will be used 
to unlock the PGP (or GPG) key used for signing requests.

=item B<-s --sub_actionid>

Substitude the actionId attribute for a time-based string.

=item B<-h --help>

Prints these docs and exits

=back

=head1 DESCRIPTION

This is a simple command line client for sending pure XML requests to the SRS.

=cut