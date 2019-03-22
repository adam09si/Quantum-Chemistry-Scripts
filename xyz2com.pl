#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use autodie;
use constant {
    DEFAULT_LEVEL => 'LEVEL',
    DEFAULT_CHARGE => '0',
    DEFAULT_MULTIPLICITY => 1,
};

( my $xyz = shift ) or print_usage();
( ( my $com = $xyz  ) =~ s/\.xyz$/.com/ ) or ( die "please enter a .xyz file!\n");

my ($level, $charge, $multiplicity);

GetOptions(
	"level:s" => \$level,
	"charge:s" => \$charge,
	"multiplicity:i" => \$multiplicity,
) or die "Error in command line arguments\n";

$level          ||= DEFAULT_LEVEL;
( $charge         ||= DEFAULT_CHARGE ) =~ s/^\\-/-/;
$multiplicity   ||= DEFAULT_MULTIPLICITY;

open my $xyz_fh, '<', $xyz;
open my $com_fh, '>', $com;

print $com_fh <<"HEREDOC";
# $level

converted from $xyz by $0

$charge  $multiplicity
HEREDOC

print "$com route line: $level\n";
print "$com charge & multiplicity: $charge  $multiplicity\n";

while (<$xyz_fh>) {
    chomp; my @line = split /[\s,]+/;
    if ( is_xyz_line(\@line) ) {
        print $com_fh $_, "\n";
    }
}

print $com_fh "\n";

sub is_xyz_line {
	my @line = @{ +shift };
	my $float = qr/^-?\d+\.\d+$/;
	if ( @line != 4 ) {
		return
	} else {
		if ( grep { $_ !~ /$float/ } @line[1 .. 3] ) {
			return
		} else {
			return 1
		}
	}
}

sub print_usage {
	print <<END_OF_HELP;

	Usage: $0 <.xyz file> [ (-level|-l) ='LEVEL'] [ (-charge|-c) =0 ] [ (-multiplicity|-m) =1 ]
	       $0 <.xyz file> -l "B3LYP/6-31G(d) opt freq"
	       $0 <.xyz file>
	       $0 <.xyz file> -c '\\-1'

	Converts an .xyz file to a .com file with the same basename.
	If a -level is not specified, the word 'LEVEL' will be printed on the route line.
	Charge and multiplicity default to '0 1' if unspecified.
	Precede any minus sign in the charge by a backslash.

END_OF_HELP
	exit;
}
