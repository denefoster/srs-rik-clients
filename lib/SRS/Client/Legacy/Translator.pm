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

package SRS::Client::Legacy::Translator;

use strict;
use warnings;

use SRS::Client::JSON::Translator;
use Carp;
use Date::Parse;

my %validTransactions = (
    whois => 'Whois',
    domaindetailsqry => 'DomainDetailsQry',
    domaincreate => 'DomainCreate',
    domainupdate => 'DomainUpdate',
    getmessages => 'GetMessages',
    getdomaindetails => 'Whois',
    udaivalidqry => 'UDAIValidQry',
    registrarcreate => 'RegistrarCreate',
    registrardetailsqry => 'RegistrarDetailsQry',
    registrarupdate => 'RegistrarUpdate',
    registraraccountqry => 'RegistrarAccountQry',
    actiondetailsqry => 'ActionDetailsQry',
);

my %validFields = (
    # Note, 'transaction' is not checked for here.

    domain_name_filter => { 'text' => 'DomainNameFilter' },

    registrant_name => 'RegistrantContact',
    registrant_phone => 'RegistrantContact',
    registrant_fax => 'RegistrantContact',
    registrant_address1 => 'RegistrantContact',
    registrant_address2 => 'RegistrantContact',
    registrant_city => 'RegistrantContact',
    registrant_country => 'RegistrantContact',
    registrant_email => 'RegistrantContact',
    registrant_postalcode => 'RegistrantContact',
    registrant_province => 'RegistrantContact',

    admin_name => 'AdminContact',
    admin_phone => 'AdminContact',
    admin_fax => 'AdminContact',
    admin_address1 => 'AdminContact',
    admin_address2 => 'AdminContact',
    admin_city => 'AdminContact',
    admin_country => 'AdminContact',
    admin_email => 'AdminContact',
    admin_postalcode => 'AdminContact',
    admin_province => 'AdminContact',

    tech_name => 'TechnicalContact',
    tech_phone => 'TechnicalContact',
    tech_fax => 'TechnicalContact',
    tech_address1 => 'TechnicalContact',
    tech_address2 => 'TechnicalContact',
    tech_city => 'TechnicalContact',
    tech_country => 'TechnicalContact',
    tech_email => 'TechnicalContact',
    tech_postalcode => 'TechnicalContact',
    tech_province => 'TechnicalContact',

    registrarpub_name => 'RegistrarPublicContact',
    registrarpub_phone => 'RegistrarPublicContact',
    registrarpub_fax => 'RegistrarPublicContact',
    registrarpub_address1 => 'RegistrarPublicContact',
    registrarpub_address2 => 'RegistrarPublicContact',
    registrarpub_city => 'RegistrarPublicContact',
    registrarpub_country => 'RegistrarPublicContact',
    registrarpub_email => 'RegistrarPublicContact',
    registrarpub_postalcode => 'RegistrarPublicContact',

    registrarsrs_name => 'RegistrarSRSContact',
    registrarsrs_phone => 'RegistrarSRSContact',
    registrarsrs_fax => 'RegistrarSRSContact',
    registrarsrs_address1 => 'RegistrarSRSContact',
    registrarsrs_address2 => 'RegistrarSRSContact',
    registrarsrs_city => 'RegistrarSRSContact',
    registrarsrs_country => 'RegistrarSRSContact',
    registrarsrs_email => 'RegistrarSRSContact',
    registrarsrs_postalcode => 'RegistrarSRSContact',

    defaulttech_name => 'DefaultTechnicalContact',
    defaulttech_phone => 'DefaultTechnicalContact',
    defaulttech_fax => 'DefaultTechnicalContact',
    defaulttech_address1 => 'DefaultTechnicalContact',
    defaulttech_address2 => 'DefaultTechnicalContact',
    defaulttech_city => 'DefaultTechnicalContact',
    defaulttech_country => 'DefaultTechnicalContact',
    defaulttech_email => 'DefaultTechnicalContact',
    defaulttech_postalcode => 'DefaultTechnicalContact',

    ns_name => 'NameServers',
    ns_ip => 'NameServers',
    ns_ip6 => 'NameServers',

    ns_filter_name => 'NameServerFilter',
    ns_filter_ip => 'NameServerFilter',
    ns_filter_ip6 => 'NameServerFilter',

    ds_key_tag => 'DS',
    ds_algorithm => 'DS',
    ds_digest_type => 'DS',
    ds_digest => 'DS',

    ds_filter_key_tag => 'DSFilter',
    ds_filter_algorithm => 'DSFilter',
    ds_filter_digest_type => 'DSFilter',
    ds_filter_digest => 'DSFilter',

    locked_date_from => 'LockedDateRange',
    effective_date_from => 'EffectiveDateRange',
    billed_until_date_from => 'BilledUntilDateRange',
    registered_date_from => 'RegisteredDateRange',
    cancelled_date_from => 'CancelledDateRange',
    trans_date_from => 'TransDateRange',
    search_date_from => 'SearchDateRange',
    result_date_from => 'ResultDateRange',
    invoice_date_from => 'InvoiceDateRange',
    log_date_from => 'LogDateRange',

    locked_date_to => 'LockedDateRange',
    effective_date_to => 'EffectiveDateRange',
    billed_until_date_to => 'BilledUntilDateRange',
    registered_date_to => 'RegisteredDateRange',
    cancelled_date_to => 'CancelledDateRange',
    trans_date_to => 'TransDateRange',
    search_date_to => 'SearchDateRange',
    result_date_to => 'ResultDateRange',
    invoice_date_to => 'InvoiceDateRange',
    log_date_to => 'LogDateRange',

    active_on => 'ActiveOn',

    field_list => 'FieldList',

    runlog_processname => 'RunLog',
    runlog_details => 'RunLog',
    runlog_actionstatus => 'RunLog',
    runlog_control => 'RunLog',
    runlog_action_id => 'RunLog',
    runlog_timestamp => 'RunLog',

    billing_term => 'Term',
    delegate => 'Delegate',
    max_results => 'MaxResults',
    skip_results => 'SkipResults',
    audit_text => {'text' => 'AuditText'},
    action_id => 'ActionId',
    udai => 'UDAI',
    new_udai => 'NewUDAI',
    renew_now => 'Renew',
    lock_request => 'Lock',
    registrar_id => 'RegistrarId',
    domain_name => 'DomainName',
    domain_name_unicode => 'DomainNameUnicode',
    source_ip => 'SourceIP',
    full_result => 'FullResult',
    registrant_contact => 'RegistrantName',
    registrant_customer_ref => 'RegistrantRef',
    originating_registrar_id => 'OriginatingRegistrarId',
    effective_registrar_id => 'RecipientRegistrarId',
    cancel => 'Cancel',
    status => 'Status',
    public_key => 'EncryptKey',
    url => 'URL',
    name => 'Name',
    accref => 'AccRef',
    allowed_2lds => 'Allowed2LDs',
    roles => 'Roles',
    name_filter => 'NameFilter',
    invoice_id => 'InvoiceId',
    processname => 'ProcessName',
    parameters => 'Parameters',
    release => 'Release',

    sysparam_name => 'SysParam',
    sysparam_value => 'SysParam',
);

sub from_request_to_xml {    
    my $fields = shift;
    my $registrar_id = shift;
    my $ver_major = shift;
    my $ver_minor = shift;

    # Find the transaction
    my $transaction;
    foreach my $field (keys %$fields) {
        if ($field =~ /Transaction:?\s*/i) {
            $transaction = delete $fields->{$field};
        }
    }
        
    my $mapped_trans = $validTransactions{lc $transaction};
    
    die "Invalid transaction: $transaction\n" unless $mapped_trans;
        
    my %data = _generate_data_structure(%$fields);
    
    return SRS::Client::JSON::Translator::from_request_to_xml(
        {
            'NZSRSRequest' => {
                VerMajor => $ver_major,
                VerMinor => $ver_minor,
                RegistrarId => $registrar_id,
                $mapped_trans => \%data,
            },
        }
    );    
}

#sub from_response_to_legacy_output {
#    my $xml = shift;
#        
#    my $data = SRS::Client::JSON::Translator::from_response_to_data($xml);
#    
#    return _generate_output($data);
#}

sub _generate_output {
    my $fields = shift;
    my $indent = shift || '';

    my $output = '';

    $indent .= '   ';

    foreach my $key (sort keys %$fields) {
        my $value = $fields->{$key};
        if (ref($value) eq 'HASH') {
            if ($value->{'$t'}) {
                $output .= "$indent$key => " . $value->{'$t'} . "\n";
            }
            else {            
                $output .= "$indent$key:\n";
                $output .= _generate_output($value, $indent);
            }
        }
        elsif (ref($value) eq 'ARRAY') {
            if (scalar @$value != 1) {
                $output .= "$indent$key List:\n";
            }                
            foreach my $element (@$value) {
                if (ref($element)) {
                    $output .= _generate_output({$key => $element}, $indent);
                }
                else {
                    $output .= "$indent   $element\n"
                }
            }
        }
        else {            
            $output .= "$indent$key => $value\n" if defined $value;
        }
    }

    $indent = substr($indent,0,-3);
    
    return $output;
}

# Convert from the legacy format to a data structure that can then be converted to something else (i.e. XML)
sub _generate_data_structure {
    my %orig_fields = @_;
    
    my %fields;
    
    # Iterate over fields and process them
    while ( my ($key, $value) = each %orig_fields) {
        # Couldn't find a value
        error ("Value missing ($key)") unless defined $value;
    
        # Reformat key/value
        $key =~ s/\:?\s?//g;
        $key = lc($key);
        $value =~ s/^\s+?//g;
        $value = '' if $value eq 'NULL';
    
        # Remove trailing index number of nameserver and ds.
        my ($stripped_key, $index) = ( $key =~ m/^((?:ns|ds)_.*)_(\d+)$/ );
        $key = $stripped_key if $index;
    
        error ("Field ($key) not recognised") unless defined $validFields{$key};
    
        # Change ActionID macro
        if ($key eq 'action_id' && $value eq '%d') {
            my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
            $year += 1900;
            $value = "$year-$mon-$mday-$hour-$min-$sec " . rand;
        }
    
        # Contacts
        if ($validFields{$key} =~ /Contact$/) {
            my ($top,$subField) = split /\_/,$key;
    
            if ($subField eq 'phone' || $subField eq 'fax') {
                my $temp_value = $value;
                $value = {};
                if ($temp_value ne '') {
                    my ($countryCode,$areaCode,$number) = splitPhone($temp_value);
                    $value = {
                        CountryCode => $countryCode,
                        AreaCode => $areaCode,
                        LocalNumber => $number,
                    };
                    
                    $fields{$validFields{$key}}{ucfirst $subField} = $value;  
                }
            }
    
            elsif ($subField eq 'address1' || $subField eq 'address2' ||
                $subField eq 'city' || $subField eq 'country' ||
                $subField eq 'postalcode' || $subField eq 'province') {
                    
                my $new_field = ucfirst $subField;
                $new_field = 'PostalCode' if $subField eq 'postalcode';  
                $new_field = 'CountryCode' if $subField eq 'country';
                    
                $fields{$validFields{$key}}{PostalAddress}{$new_field} = $value;  
            }
    
            else {
                $fields{$validFields{$key}}{ucfirst $subField} = $value;
            }
        }
    
        # Date Ranges
        elsif ($validFields{$key} =~ /DateRange$/) {
            $key =~ /\_([a-z]+?)$/;
            my $subField = $1;
    
            $value =~ s/\,/ /g;
            my $type = ucfirst $subField;
            
            my ($ss,$mm,$hh,$day,$month,$year,$zone) = strptime($value);
    
            $fields{$validFields{$key}}->{$type} = {
                Year => $year+1900,
                Month => $month+1,
                Day => $day,
                Hour => $hh,
                Minute => $mm,
                Second => $ss // 0,
            };
        }
   
        # Name Servers
        elsif ($validFields{$key} eq 'NameServers') {
            my ($top,$subField) = split /\_/,$key;
    
            my $subKey = ($subField eq 'name' ? 'FQDN' : ($subField eq 'ip' ? 'IP4Addr' : 'IP6Addr'));
            
            $fields{$validFields{$key}}->{Server}->[$index-1]->{$subKey} = $value;
        }
    
        # Name Server Filter
        elsif ($validFields{$key} eq 'NameServerFilter') {
            my ($top,$middle,$subField) = split /\_/,$key;

            my $subKey = ($subField eq 'name' ? 'FQDN' : ($subField eq 'ip' ? 'IP4Addr' : 'IP6Addr'));
            
            my @nameServerFilter;
            
            $fields{$validFields{$key}}->{ServerFilter}->[$index-1]->{$subKey} = $value;
        }
    
        # DS
        elsif ($validFields{$key} eq 'DS') {
            my ($top,@subFields) = split /\_/,$key;
   
            my $subKey = join '_', @subFields;
            
            if ($subKey eq 'digest') {
                $value = {'$t' => $value};
            }
            
            $subKey =~ s/(\b|_)(\w)/$1\u$2/g;
            $subKey =~ s/_//g;
            
            $fields{DNSSEC}->{DS}->[$index-1]->{$subKey} = $value;
            
        }
    
        # DS Filter
        elsif ($validFields{$key} eq 'DSFilter') {
            my ($top,$filter,@subFields) = split /\_/,$key;
    
            my $subKey = join '_', @subFields;
            
            if ($subKey eq 'digest') {
                $value = {'$t' => $value};
            }
            
            $subKey =~ s/(\b|_)(\w)/$1\u$2/g;
            $subKey =~ s/_//g;            
            
            $fields{DNSSECFilter}->{DSFilter}[$index-1]->{$subKey} = $value;
        }
    
        elsif ($validFields{$key} eq 'FieldList') {
            my @filters = split /\,/,$value;
    
            my %flist;
            for my $filter ( @filters ) {
                $flist{$filter} = 1;
            }

            $fields{$validFields{$key}} = \%flist;
       }
       
       elsif (ref $validFields{$key} eq 'HASH') {
            if (my $name = $validFields{$key}->{text}) {
                # Text sub element
                $fields{$name} = { '$t' => $value };   
            } 
       }
    
        # Everything else
        else {
            $fields{$validFields{$key}} = $value;
        }
    }
    
    return %fields;
}

sub splitPhone {
    my $phone = shift or croak "Phone number not supplied";
    $phone =~ m/^\+*(\d+)[ \-]?\(?(\d*)\)?[ \-]?(.+)$/o;
    return ($1,$2,$3);
}

# TODO: replace me?
sub error {
    Carp::confess @_;   
}

1;

__END__

=head1 NAME

SRS::Client::Legacy::Translator - translate from the 'legacy' format to XML

=head1 DESCRIPTION

This module contains functions to convert from the 'legacy' input format of 
key/value pairs used by SRSClient2 to XML. For a full description of this
format, and the list of field names see the SRSClient2 documentation.

=head1 FUNCTIONS

=head2 from_request_to_xml(\%fields, $registrar_id, $ver_major, $ver_minor)

Generate and return an SRS XML Request string based on the fields in \%fields.
These fields are expected to be in the legacy key/value pair format described
in the SRSClient2 documentation.

The top-level NZSRSRequest element is populated with attributes based on
$registrar_id, $ver_major and $ver_minor respectively.

=head2 from_response_to_legacy_output($xml)

Given an XML response string, return a string containing the fields of the
response in a format suitable for display by the SRSClient2.

