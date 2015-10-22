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
package SRS::Client::JSON;

use strict;
use warnings;

use SRS::Client::JSON::Translator;
use SRS::Client::Options::SendJSON;

use File::Slurp qw(read_file);
use XML::LibXML;
use XML::LibXSLT;

use base 'SRS::Client';

sub new {
    my ($class,@args) = @_;
    
    my $optionParser = SRS::Client::Options::SendJSON->new();
    my $self = $optionParser->getOptions(\@args);

    bless ($self, $class);
    
    return $self;
}

sub run {   
    my $self = shift;
    
    $self->processCommandline();
    $self->checkCpanLibs();

    my $json;
    if ($self->{json}) {
        $json = $self->{json};
    }
    else {
        $json = read_file($self->{file});
    }
    
    my $xslt;
    # Read in the xslt if they've provided one (or die if the file can't be found)
    #  We do this now so we don't do a whole request before checking they haven't given
    #  us a valid file or something.
    if ($self->{xslt}) {
        $xslt = eval {
            XML::LibXML->load_xml(location => $self->{xslt});
        };
        
        if ($@) {
            my $error = $@;
            $error =~ s| at .+ line .+$||;
            chomp $error;
            $self->error("Couldn't load xslt file ($error)");
        }
    }

    my $xml = SRS::Client::JSON::Translator::from_request_to_xml($json);
    
    warn "Request XML: $xml\n" if $self->{debug};
    
    my ($error, $response) = $self->sendXML($xml,"sendJSON");
    
    if ($error) {
        print "Communication error: $error\n";
        return $error;
    }
    
    warn "Response XML: $response\n" if $self->{debug};

    if ($self->{xslt}) {
        my $xml_dom = XML::LibXML->load_xml(string => $response);        
        
        my $lib_xslt = XML::LibXSLT->new();
        my $stylesheet = $lib_xslt->parse_stylesheet($xslt);
        
        my $results = $stylesheet->transform($xml_dom);
    
        return $results->toString();
    }
    else {
        return SRS::Client::JSON::Translator::from_response_to_json($response);
    }
}

1;

__END__

=head1 NAME

SRS::Client::JSON - encapsulates the functionality of the sendJSON command-line client

=head1 SYNOPSIS

 my $client = SRS::Client::JSON->new(@ARGV);
 print $client->run() . "\n";

=head1 DESCRIPTION

This module encapsulates the functionality of the sendJSON.pl SRS command-line
client (see that script's documentation for more details).

No extra functionality is provided in this module, however it could be used
directly rather than via the command-line. This might be useful if you want
to embed this functionlaity into a Perl application (e.g. a web application).

=head1 METHODS

=head2 new(@args)

Constuct a new SRS::Client::JSON object. Accepts an array of arguments that
are processed as command-line parameters. See the 'OPTIONS' section of the
sendJSON.pl documentation for a description of the parameters accepted.

=head2 run()

Execute a request based on the parameters passed to new. This involves
converting the JSON to XML, signing it, sending it to the SRS, waiting for a
response, and converting that XML response to JSON. The resulting JSON is
returned by this method.

=cut
