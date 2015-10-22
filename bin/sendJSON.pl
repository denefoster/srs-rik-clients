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

use SRS::Client::JSON;

my $client = SRS::Client::JSON->new(@ARGV);
print $client->run();

1;

__END__

=head1 NAME

sendJSON.pl - an SRS command-line client that accepts input and displays output as JSON

=head1 SYNOPSIS

sendJSON.pl [options]

  Options:
    --registrar_id   -r   (required) id of the registrar to send requests as
    --file           -f   location of the file containing the JSON request
    --debug          -d   display XML request and response       
    --url                 The URL of the srs system
    --timeout        -t   time the client should wait for the server
    --gpg_id              The GPG id that should sign the request
    --gpg_public          The path to the GPG public keyring file
    --gpg_secret          The path to the GPG secret keyring file
    --gpg_passphrase      The passphrase required to unlock the GPG key
    --gpg_passphrase_file File which contains the gpg_passphrase
    --xslt           -x   Post process the XML output with the specified xslt
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

The file containing the JSON request to be converted to XML, signed and sent to
the SRS. The format of the JSON is described below.

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

=item B<-x --xslt>

Post process the resulting XML output with the specified xslt.

=item B<-h --help>

Prints these docs and exits

=back

=head1 DESCRIPTION

A command-line client for the SRS that accepts input as JSON, and returns
output as JSON. JSON is converted to XML via a set of rules described below.

=head1 INPUT FORMAT

The format accepted in the file specified on the command-line is a JSON
structure representing an SRS XML request. Although the SRS protocol supports
more than one transaction (Whois, DomainCreate, etc) per request, sendJSON does
not, and an error will be raised if this is attempted.

The format of the JSON structure is based directly on the SRS XML definition
(i.e. the DTD). As such, no formal defintion of the JSON structure is provided.
Instead, the following rules are used for converting an XML document to JSON:

=over 8

=item *

XML elements are converted to JSON objects

For example:

 <element/>

Is converted to:

 {"element": {}}

=item *

XML attributes are converted to JSON string properties

For example:

 <element attribute="value"/>

Is converted to:

 {"element:" { "attribute": "value" }}

=item *

XML text nodes are converted to a property called '$t'

For example:

 <element>text</element>

Is converted to:

 {"element": { "$t": "text" }}

=item *

Nested XML elements are converted to nested JSON structures

For example:

 <element attribute="value"><inner inside="value2"/></element>

Is converted to:

 {
     "element": {
         "attribute": "value",
         "inner": {
             "inside": "value2"
         }
     }
 }

=item *

Repeated XML elements are converted to JSON arrays

For example:

 <element><inner attribute="value1"><inner attribute="value2"></element>

Is converted to:

 {
     "element": {
        "inner": [
            {
                "attribute": "value1",
            },
            {
                "attribute": "value2",
            }
       ]
    }
 }

=back

The above rules are sufficient for decribing the enitre SRS protocol. Note, as
there are no cases in the SRS protocol where element names are the same as
attribute names, there is no need to prefix an attribute property name to
distiguish it from an element, as with some other approaches for converting
from XML to JSON.

=head2 Whois Example

To further demonstrate the above rules, the below example shows the conversion
of a Whois request from XML to JSON.

The original XML Whois request is:

 <NZSRSRequest VerMajor="5" VerMinor="10" RegistrarId="90">
    <Whois DomainName="test.co.nz" SourceIP="1.2.3.4" FullResult="0"/>
 </NZSRSRequest>

The request as JSON is:

 {
   "NZSRSRequest" : {
      "VerMajor" : "5",
      "VerMinor" : "10",
      "RegistrarId" : "90",
      "Whois" : {
          "DomainName": "test.co.nz",
          "FullResult": 0,
          "SourceIP": "1.2.3.4"
      }
   }
 }

Note, as the conversion is rules based, further SRS examples are not provided.
See the XML examples distributed in the RIK for examples of requests that can
be converted to JSON using the above rules.

=cut

