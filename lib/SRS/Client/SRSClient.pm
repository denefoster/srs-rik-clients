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
package SRS::Client::SRSClient;

use strict;
use warnings;

use File::Slurp qw(read_file);
use Pod::Usage;

use Carp;

use SRS::Client::Legacy::Translator;
use SRS::Client::Versions;
use SRS::Client::Options::SRSClient;

use base 'SRS::Client';

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

sub new {
    my $class = shift;
    my @args = @_;
    
    my $optionParser = SRS::Client::Options::SRSClient->new();
    my $self = $optionParser->getOptions(\@args);

    bless ($self, $class);
    
    return $self;
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

    for my $required ( "registrar_id", "url" ) {
        if ( ! $self->{$required} ) {
            $self->error("Required option missing: $required");
        }
    }
}

sub run {   
    my ($self) = @_;
    
    $self->processCommandline();
    $self->checkCpanLibs();

    my @tempFields;

    # Either read the file, or the parameters
    if ($self->{file}) {
        my $data = read_file($self->{file});

        # Split the fields up
        @tempFields = split /\n+/,$data;

        # Remove Comments.
        @tempFields = grep {!/^#/} @tempFields;

        @tempFields = map {split/\: /,$_} @tempFields;
    } else {
        @tempFields = @ARGV;

        # Get rid of any arguments that are flags
        foreach my $field (@ARGV) {
            if ($field =~ /^-.+$/) {
                shift @tempFields;
                shift @tempFields;
            }
        }
        
        if (! @tempFields) {
            $self->error("Please provide either a file or key/value pairs");   
        }

    }

    # Must have an even number of parameters
    $self->error ("Invalid parameter format (@tempFields)") if scalar(@tempFields) % 2;


    my %tempFields = @tempFields;

    my ($major, $minor) = SRS::Client::Versions::get_rik_version();
    my $xml = SRS::Client::Legacy::Translator::from_request_to_xml(
        \%tempFields,
        $self->{registrar_id},
        $major,
        $minor,
    );
    
    warn "Request: $xml\n" if $self->{debug};

    my ($error, $response) = $self->sendXML($xml,"SRSClient2");    

    if ($error) {
        print "Communication error: $error\n";
        exit;
    }

    warn "Response: $response\n" if $self->{debug};

    # TODO: handle error responses?
    print "Results:\n";
    print SRS::Client::Legacy::Translator::from_response_to_legacy_output($response);
}

1;

__END__

=head1 NAME

SRS::Client::SRSClient - encapsulates the functionality of the SRSClient command-line client

=head1 SYNOPSIS

 my $client = SRS::Client::SRSClient->new(@ARGV);
 print $client->run() . "\n";

=head1 DESCRIPTION

This module encapsulates the functionality of the SRSClient SRS command-line
client (see that script's documentation for more details).

No extra functionality is provided in this module, however it could be used
directly rather than via the command-line. This might be useful if you want
to embed this functionlaity into a Perl application (e.g. a web application).

=head1 METHODS

=head2 new(@args)

Constuct a new SRS::Client::SRSClient object. Accepts an array of arguments that
are processed as command-line parameters. See the 'OPTIONS' section of the
SRSClient documentation for a description of the parameters accepted.

=head2 run()

Execute a request based on the parameters passed to new. This involves
converting the XML to XML, signing it, sending it to the SRS, waiting for a
response, and converting that XML response to XML. The resulting XML is
returned by this method.

=cut
