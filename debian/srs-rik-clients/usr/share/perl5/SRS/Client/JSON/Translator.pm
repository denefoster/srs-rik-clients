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

package SRS::Client::JSON::Translator;

use strict;
use warnings;

use Carp;

use XML::XML2JSON;
use XML::LibXSLT;
use XML::LibXML;
use JSON::Any qw(XS);
use Encode;

sub from_request_to_xml {
    my $stream = shift;    

    if (! ref $stream) {
        $stream = encode("utf-8",$stream) if utf8::is_utf8($stream);
                
        $stream =~ s/^\s*//;    
        
        my $j = JSON::Any->new;
        
        eval {
            $stream = $j->decode($stream);
        };
        if ($@) {
            die "Error parsing JSON: $@";   
        }
    }
    
    # Check they're not trying to send more than one transaction in the request, which
    #  we don't support (because the JSON won't preserve the order)
    if ($stream->{NZSRSRequest}) {
        my $trans_count;
        foreach my $key (keys %{$stream->{NZSRSRequest}}) {
            # If it's a hash, we count it as one, if it's an array, we count 
            #  it as the number of items in the array
            $trans_count++ if ref $stream->{NZSRSRequest}{$key} eq 'HASH';
            
            $trans_count+= scalar @{ $stream->{NZSRSRequest}{$key} }
                if ref $stream->{NZSRSRequest}{$key} eq 'ARRAY';
        }
        
        if ($trans_count > 1) {
            die "It looks like you've provided multiple transactions in one request, which is not supported\n";   
        }
    }    
    
    my $xml_dom = eval { 
        my $converter = XML::XML2JSON->new();
        
        $converter->obj2dom($stream);

    };
    if ($@) {
        die "Error in converting JSON to XML: $@\n";           
    }
    
    # Now apply stylesheet to put elements into the correct order
    my $xslt = XML::LibXSLT->new();
    
    my $order_xslt = _find_xslt('reorder_xml.xsl');
    
    my $style_doc = XML::LibXML->load_xml(location => $order_xslt);
  
    my $stylesheet = $xslt->parse_stylesheet($style_doc);
  
    my $results = $stylesheet->transform($xml_dom);
    
    return $results->toString();
}

sub from_response_to_data {
    my $xml = shift;
    
    my $converter = XML::XML2JSON->new(
        attribute_prefix => '',
    );       
    
    my $data = $converter->xml2obj($xml);
    delete $data->{version};
    delete $data->{encoding};
    
    return $data;
}

sub from_response_to_json {
    my $xml = shift;
    
    my $data = from_response_to_data($xml);
    
    return JSON::Any->new( pretty => 1 )->encode($data);        
}

# Find an XSLT (or really any file) in @INC
sub _find_xslt {
    my $xslt = shift;   
    
    foreach my $path (@INC) {
        if (-e "$path/$xslt") {
            return "$path/$xslt";
        }
    }
    
    croak "Couldn't find $xslt in any of these paths: " . join ' ',@INC;
}

1;

__END__

=head1 NAME

SRS::Client::JSON::Translator - translate JSON into SRS XML and back

=head1 SYNOPSIS

 # Convert from JSON to XML
 $xml = SRS::Client::JSON::Translator::from_request_to_xml($json);
 
 # Convert from a data structure (hash ref) to XML
 $xml = SRS::Client::JSON::Translator::from_request_to_xml(\%data);
 
 # Convert from XML to JSON
 $json = SRS::Client::JSON::Translator::from_response_to_json($xml);
 
 # Convert from XML to a data structure (hash ref)
 my $data = SRS::Client::JSON::Translator::from_response_to_data($xml);

=head1 DESCRIPTION

This module contains utility functions to convert from JSON to XML and back
again. Note, it is not a generic converter of JSON <-> XML. It only works for
the SRS transactions that have been implemented. This is primarily because the
SRS protocol requires elements to be in a certain order, but the JSON structure
does not preserve this order. Therefore this module must have knowledge of the
required order of the fields for each transaction.

The rules for converting from JSON <-> XML are described in the sendJSON
documentation.

=head1 FUNCTIONS

=head2 from_request_to_xml($stream)

Converts $stream to an SRS XML request, which is returned. $stream can be a JSON
string or an equivilent data structure in a hash ref. If it's a JSON string, 
some efforts are made to ensure utf8 encoding is handled correctly.

Note, this function does not accept a structure containing more than one
transaction per SRS request document. If this case is detected, an exception
is thrown.

=head2 from_response_to_json($xml)

Convert an XML string containing an SRS response to JSON, which is returned as
a string. The JSON is "prettied", i.e. returned as human readable.

=head2 from_response_to_data($xml)

As from_response_to_json() but returns a hash ref containing the equivilent
data structure, rather than a JSON string.

=cut
