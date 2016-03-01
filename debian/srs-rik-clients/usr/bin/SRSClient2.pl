#!/usr/bin/perl
#--------------------------------------------------------------------------------------------------
#
# Copyright 2002-2004 NZ Registry Services
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

use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use SRS::Client::SRSClient;

my $client = SRS::Client::SRSClient->new(@ARGV);
print $client->run();

1;

__END__

=head1 NAME

SRSClient2

=head1 SYNOPSIS

SRSClient2 [options] Transaction: <transaction_type> [fieldname1: value1 fieldname2: value2 ...]

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
    --help           -h   display documentation

=head1 DESCRIPTION

This is a command-line based client for the SRS. It allows single transactions to be sent to
the server. For more information, see supporting registrar kit documentation.

=head1 STATUS

While there are no plans to remove this client, its use is not recommended.
No new transactions will be added, and changes to existing transactions will
not be made.

The recommended command-line tools for connecting to the SRS are sendJSON, or sendXML.

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

The file containing the request to be converted to XML, signed and sent to
the SRS.

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

=item B<-h --help>

Prints these docs and exits

=back

=head1 TRANSACTIONS

The following transaction types are supported. (All case insensitive).

=over 4

=item * Whois (alias: GetDomainDetails)

=item * DomainDetailsQry

=item * DomainCreate

=item * DomainUpdate

=item * GetMessages

=item * UDAIValidQry

=item * RegistrarCreate

=item * RegistrarUpdate

=item * RegistrarDetailsQry

=back

=head2 Fields

Fields can either be specified directly on the command line, or read in from file, specified with the
'-f' flag. The format is fieldname: value. Fieldnames are case insensitive. Supported fields are:

* B<Transaction>: [required] One of the transaction types listed above.

* B<Domain_name>: the domain name (standard ASCII)

* B<Domain_name_unicode>: the domain name in unicode

* B<Domain_name_filter>: a list of domain names, separated by commas.
If the transaction is DomainDetailsQry then the list of domain names B<CAN> contain
names using ? and * wild cards.
If the transaction is DomainUpdate then the list of domain names B<CANNOT> contain
names using ? and * wild cards (see registrar kit documentation for information on this). 

* B<Ns_name_n>: The FQDN (fully qualified domain name) of Name server I<n>.
The I<n> should be a positive integer.

* B<Ns_ip_n>: The IPv4 address of Name server I<n>. The I<n> should be a positive integer.

* B<Ns_ip6_n>: The IPv6 address of Name server I<n>. The I<n> should be a positive integer.

* B<DS_key_tag_n>: The Key Tag of DNS DS record I<n> for the domain.
The I<n> should be a positive integer. Up to 8 DS records are allowed.

* B<DS_algorithm_n>: The Algorithm of DNS DS record I<n> for the domain.
The I<n> should be a positive integer.

* B<DS_digest_type_n>: The Digest Type of DNS DS record I<n> for the domain.
The I<n> should be a positive integer.

* B<DS_digest_n>: The Digest of DNS DS record I<n> for the domain.
The I<n> should be a positive integer.

* B<Locked_date_from>: Initial date for queries on domains locked after this date. All date fields need to be in the format: 
'dd/mm/yyyy,hh::mm::ss' (Seconds are optional) For example:

    Locked_date_from: 28/05/2002,12:30
    (indicates a date from 29/05/2002, 12:30pm)

* B<Locked_date_to>: End date for queries on domains locked before this date.

* B<Effective_date_from>: Initial date for queries on domains effective after this date.

* B<Effective_date_to>: End date for queries on domains effective befire this date.

* B<Billed_until_date_from>: Initial date for queries on domains billed until after this date.

* B<Billed_until_date_to>: End date for queries on domains billed until before this date.

* B<Registered_date_from>: Initial date for queries on domains registered after this date.

* B<Registered_date_to>: End date for queries on domains registered before this date.

* B<Cancelled_date_from>: Initial date for queries on domains cancelled after this date.

* B<Cancelled_date_to>: End date for queries on domains cancelled before this date.

* B<Trans_date_from>: Initial date for queries on transactions after this date.

* B<Trans_date_to>: End date for queries on transactions before this date.

* B<source_ip>: Specify to NZRS where this whois request came from

* B<full_result>: Defaults to True. A value of 0 in this field will return only the domain name and availability status for a whois query.

* B<Field_list>: Comma separated list of fields to return. Valid fields are:

=over 4

=item * DomainName

=item * Status

=item * NameServers

=item * RegistrantContact

=item * RegisteredDate

=item * AdminContact

=item * TechnicalContact

=item * Delegate

=item * RegistrarId

=item * RegistrarName

=item * RegistrantRef

=item * Term

=item * LastActionId

=item * BilledUntil

=item * CancelledDate

=item * LastChangeDate

=item * LastChangedBy

=item * AuditText

=back

* B<Billing_term>: Integer indicating billing term in months.

* B<Delegate>: Defaults to 1. If 0, the domain will not be delegated to the DNS servers.

* B<Max_results>: Maximum number of results to display.

* B<Skip_results>: Number of results to be skipped. '0' indicates no result is skipped.

* B<Audit_text>: Audit text supplied by registrar

* B<Action_id>: The action ID. Specifying %d will use a timestamp value.

* B<UDAI>: The Unique Domain Authentication Identifier.

* B<New_UDAI>: Requests a new UDAI to be returned.

* B<Renew_now>: Renew now flag. '0' indicates false, '1' indicates true.

* B<Cancel>: Cancel domain flag. '0' indicates false, '1' indicates true.

* B<Registrar_id>: Registrar ID.

* B<Status>: Domain Status. Valid Status values are:

=over 4

=item * Active

=item * PendingRelease

=back

* B<URL>: The URL of a registrar's home page.

* B<Name>: The name of the registrar

* B<Accref>: Registrar's Accounting Reference

* B<Registrant_contact>: The contact identifier of the registrant.

* B<Registrant_customer_ref>: Registrar's reference to the registrant.

* B<Registrant_name>: Name of the registrant contact.

* B<Registrant_phone>: Voice phone contact of the Registrant, in the format

    +(country_code)-(area_code)-(local_number)
    eg. +64-4-4567890

The '+' is optional and an extra '-' can optionally be placed in the local_number.

* B<Registrant_fax>: Fax number of the registrant, in the same format as Registrant_phone.

* B<Registrant_address1>: Address line 1 of the registrant

* B<Registrant_address2>: Address line 2 of the registrant

* B<Registrant_city>: City of the registrant

* B<Registrant_country>: Two letter country code of the registrant.

* B<Registrant_postalcode>: Postal code of the registrant.

* B<Registrant_email>: Email address of the registrant.

* B<Other Contact Fields>: All other contact fields follow the same format as registrant (with the
exception of customer_ref and contact fields), but use one of the following as a prefix:

=over 4

=item * Admin

(Administrative Contact)

=item * Tech

(Technical Contact)

=item * RegistrarSRS

(Registrar SRS Contact)

=item * RegistrarPub

(Registrar Public Contact)

=item * DefaultTech

(Registrar Default Technical Contact)

=back

Eg. The Administrative Contact Name is specified with the 'Admin_name' field.

=head1 Examples

=head2 Example 1: current details of a domain

Transaction: DomainDetailsQry
Domain_Name_Filter: testdomain.net.nz
Field_list: Status,NameServers,RegistrantContact,RegisteredDate,AdminContact,TechnicalContact,LockedDate,Delegate,RegistrarId,RegistrarName

=head2 Example 2: transfer and renew domain

Transaction: DomainUpdate
Action_ID: transfer_renew_test_102610200401
Domain_Name_Filter: test.co.nz
billing_term: 10
UDAI: er9EU6Ut
Renew_now: 1
audit_text: "transfer and renew domain for 10 months"

B<For more examples refer to the 'templates' folder in the RIK>

=cut
