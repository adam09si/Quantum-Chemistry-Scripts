#!/usr/bin/env perl

# PLACE THIS FILE IN THE SAME DIRECTORY AS addchk.pl

package TestRT;

use 5.10.1; # System Perl on Hoffman2
use warnings;
use strict;
use constant TESTRT => '/u/local/apps/gaussian/09d01/g09/testrt';

sub test_route_line {
	my $com = shift;
	my @com_lines = @{ $_[0] };

	if ( -e TESTRT ) {
	} else {
		print STDERR <<END_OF_WARNING;
	
Gaussian's testrt utility, specified in:
@{[ TESTRT ]}
doesn't exist.
Syntax of input file not checked.
	
END_OF_WARNING
		return;
	}
	
	my @route_lines = grep /^#/, @com_lines;
	if ( ! @route_lines ) {
		die "No route lines found in $com!\n";
	}
	print ">>>\tChecking the following ";
	print @route_lines > 1 ? @route_lines.''." route lines\n" : "route line\n";
	print "\t", join "\t", @route_lines;
	
	my $route_line_has_error;
	foreach my $route_line ( @route_lines ) {
		chomp $route_line;
		my $response = `@{[ TESTRT ]} \'$route_line\'`;
		if ( $response =~ /^ Error termination/m ) {
			print STDERR <<END_OF_WARNING;

The testrt utility detects an error in $com. Output from testrt:
$response
END_OF_WARNING
			$route_line_has_error = 1;
		} 
	}
	return $route_line_has_error;
}	

1;
