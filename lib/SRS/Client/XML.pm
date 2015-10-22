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
package SRS::Client::XML;

use strict;
use warnings;

use File::Slurp qw(read_file);
use Time::HiRes qw (gettimeofday);
use Encoding::FixLatin;

use SRS::Client::Options::SendXML;

use base 'SRS::Client';

sub new {
    my $class = shift;
    my @args = @_;
    
    my $optionParser = SRS::Client::Options::SendXML->new();
    my $self = $optionParser->getOptions(\@args);

    bless ($self, $class);
    
    return $self;
}

sub run {   
    my ($self) = @_;
    
    $self->processCommandline();
    $self->checkCpanLibs();

    my $request = read_file($self->{file});
    
    # LogMessageGenerator captures stuff and swallows it. Make sure it gets output somewhere
    $ENV{SRS_LOG_DEST} = 'stderr';
    $ENV{SRS_LOG_NO_STACK_DUMPS} = 1;
    $ENV{SRS_LOG_LEVEL} = 'ERROR';

    if ( $self->{sub_actionid} ) {
        my ($seconds, $microseconds) = gettimeofday;
        my $id = time . '.' . $microseconds;

        $request =~ s/ActionId="(.*?)"/ActionId="$1 $id"/g;
    }

    $request = Encoding::FixLatin::fix_latin($request);
    my ($sendError, $xmlResponse) = $self->sendXML($request,"sendXML");

    if ($sendError) {
        print $sendError, "\n";
        return $sendError;
    }

    return $xmlResponse;
}

1;

__END__

=head1 NAME

SRS::Client::XML - encapsulates the functionality of the sendXML command-line client

=head1 SYNOPSIS

 my $client = SRS::Client::XML->new(@ARGV);
 print $client->run() . "\n";

=head1 DESCRIPTION

This module encapsulates the functionality of the sendXML.pl SRS command-line
client (see that script's documentation for more details).

No extra functionality is provided in this module, however it could be used
directly rather than via the command-line. This might be useful if you want
to embed this functionlaity into a Perl application (e.g. a web application).

=head1 METHODS

=head2 new(@args)

Constuct a new SRS::Client::XML object. Accepts an array of arguments that
are processed as command-line parameters. See the 'OPTIONS' section of the
sendXML.pl documentation for a description of the parameters accepted.

=head2 run()

Execute a request based on the parameters passed to new. This involves
converting the XML to XML, signing it, sending it to the SRS, waiting for a
response, and converting that XML response to XML. The resulting XML is
returned by this method.

=cut
