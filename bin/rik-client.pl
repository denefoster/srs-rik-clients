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

use strict;
use warnings;

use SRS::Client::XML;
use SRS::Client::JSON;
use SRS::Client::SRSClient;

use Getopt::Long;

my $output;
my $help;
my $verbose;

GetOptions (
    'output|o=s' => \$output,
    'help|h'     => \$help,
    'verbose|v'  => \$verbose
);

if ($help) {
    print "NZRS RIK Client provides the following options:\n";
    print "--output|-o:\tCan be one of the following: xml, json or srsclient. Defaults to xml.\n";
    print "--help|-h:\t This dialog.\n";
    print "--verbose|-v:\tVerbose output.\n";
}
else {

    $output //= 'xml';

    my $client;

    if ($output eq 'xml') {
        $client = SRS::Client::XML->new(@ARGV);
    }
    elsif ($output eq 'json') {
        $client = SRS::Client::JSON->new(@ARGV);
    }
    
    print $client->run();
    
}