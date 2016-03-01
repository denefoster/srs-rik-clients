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

package SRS::Client::Versions;

use strict;
use warnings;

use FindBin;

sub check_versions {
    my %versions = get_versions();
        
    return 1 unless $versions{rik_version} && $versions{cpan_libs_version};
    
    my ($rik_major, $rik_minor) = parse_version($versions{rik_version});
    my ($cpan_libs_major, $cpan_libs_minor) = parse_version($versions{cpan_libs_version});
    
    return $rik_major == $cpan_libs_major && $rik_minor == $cpan_libs_minor;
}

my ($rik_version, $cpan_libs_version, $platform_name);
sub get_versions {
    if (! $rik_version && ! $cpan_libs_version) {    
        for my $location ( 'VERSION', '../VERSION.txt' ) {
            my $rik_version_file = $FindBin::Bin . "/$location";
            if (-f $rik_version_file) {
                open(my $fh, '<', $rik_version_file);
                $rik_version = <$fh>;
                close($fh);
                chomp $rik_version;
            }
        }
        
        my $cpan_libs_version_file = $FindBin::Bin . '/../srs_rik_cpan_libs/VERSION';
        if (-f $cpan_libs_version_file) {        
            open(my $fh, '<', $cpan_libs_version_file);
            $cpan_libs_version = <$fh>;
            close($fh);
            chomp $cpan_libs_version;
        }
        
        my $cpan_libs_platform_file = $FindBin::Bin . '/../srs_rik_cpan_libs/PLATFORM';
        if (-f $cpan_libs_platform_file) {
            open(my $fh, '<', $cpan_libs_platform_file);
            $platform_name = <$fh>;
            close($fh);
            chomp $platform_name;            
        }
    }
    
    return (
        rik_version => $rik_version,
        cpan_libs_version => $cpan_libs_version,
        cpan_libs_platform => $platform_name,
    );
}

sub get_rik_version {
    my %versions = get_versions();
    
    return parse_version($versions{rik_version});   
}

sub parse_version {
    my $version = shift;   
    
    my ($major, $minor) = $version =~ m/(\d+)-(\d+)/;
    
    return ($major, $minor);
}

1;

__END__

=head1 NAME

SRS::Client::Versions - Tools relating to versions used by the SRS command line clients

=head2 SYNOPSIS

 # Get current RIK version
 my ($major, $minor) = SRS::Client::Versions::get_rik_version();
 
 # Get version strings for rik and cpan libs
 my %versions = SRS::Client::Versions::get_versions();

 # Check rik and cpan libs versions match
 my $versions_match = SRS::Client::Versions::check_versions();

 # Parse a version string
 my ($major, $minor) = SRS::Client::Versions::parse_version($version);

=head1 DESCRIPTION

These functions extract information about the current version of the RIK
and CPAN libs being used (if any). This information is based on the VERSION
file found in the root directory of these archives. The location of this file
is found based on the location of the executable currently being run.
Therefore, moving files outside their original location could cause these
tools to fail. However, attempts are made to fail gracefully - if the VERSION
file cannot be found, it is silently ignored.

=head1 FUNCTIONS

=head2 get_versions()

Returns a hash containing details of the RIK and CPAN libs version being used.
The version information is returned as a version string, which takes the
format:

 release-x-y

Where x is the major version number, and y is the minor version number.

(Note, this format may be subject to change. While it is safe to compare two
version strings for equality, if you need to extract the major and minor 
version numbers, use parse_versions()).

The hash returned contains the RIK version in the 'rik_version' key, and the
CPAN libs version in the 'cpan_libs_version' key.

Note, if the version information cannot be found (i.e. the VERSION files are
not in the expected locations) the version strings are returned as undef, and
no other failure is reported. In the case of CPAN libs, this may indicate
they're not being used by the current executable.

=head2 check_versions()

Checks that the RIK version matches the CPAN libs version (if it's being used).
Returns true if the versions match, false otherwise. This check is fairly
lenient. If the versions of either the RIK or CPAN libs cannot be found, this
check returns success.

=head2 parse_versions($version)

Parses a version string returned by get_versions(), extracting and returning
the major and minor version numbers.

=head2 get_rik_version()

Returns the major and minor version number of the RIK being used.

=cut
