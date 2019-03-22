#!/usr/bin/env perl
use strict;
use warnings;
use feature 'state';
use autodie;
use Cwd 'abs_path';
use Getopt::Long;
#use Data::Dumper;
use File::Path 'make_path';
use File::Basename;
use Term::ANSIColor qw(:constants);
use lib "$ENV{HOME}/bin";
use testrt;
use solvent_abbr;
use constant {
	DEFAULT_MEMORY => 1024,
};

$Term::ANSIColor::AUTORESET = 1;

my @coms;
my $memory;
my $verbose;
my ( $OldOut, $OldChk, $OldCharge, $OldMultiplicity, $OldRouteLines_ref, $lookup );

GetOptions (    "input=s{1,}" =>  \@coms,
		"memory:i" => \$memory,
		"verbose"  => \$verbose,
		"oldChk=s"   => \$OldOut,
		"lookup=s" => \$lookup,
	) or print_usage();

if ( defined $lookup ) {
	print_usage() if ! $lookup;
	my ( $abbrs, $fulls ) = lookup_solvent_abbreviations($lookup);
	if ( @$abbrs ) {
		print "Abbreviation(s) for $lookup (case-insensitive): @$abbrs\n";
	} elsif ( @$fulls ) {
		print "'$lookup' will be converted by this script to '@$fulls'\n";
	} else {
		print "'$lookup' is undefined\n";
	}
	exit;
}

if ( ( ! defined $memory ) || ( defined $memory && $memory eq '' ) ) {
	$memory = DEFAULT_MEMORY;
}

print_usage() if ! @coms;

if ( $OldOut ) {
	if ( $OldOut !~ /\.(?:out|log)$/ ) {
		die "Please enter a Gaussian .out or .log file as the argument of -o\n";
	}
	$OldOut = abs_path( $OldOut );
	if ( ! -e $OldOut ) {
		print STDERR <<END_OF_ERROR_MESSAGE;

The output file:
$OldOut
doesn't exist.
Please check and try again.
I haven't touched the original input file @coms.

END_OF_ERROR_MESSAGE
		die;
	}
	( $OldCharge, $OldMultiplicity, $OldChk, $OldRouteLines_ref ) = parse_for_ccmm( $OldOut );
	if ( ! $OldChk ) {
		print STDERR <<END_OF_ERROR_MESSAGE;

I couldn't find a \%chk= line in the output file:
$OldOut
Please check and try again.
I haven't touched the original input file @coms.

END_OF_ERROR_MESSAGE
		die;
	}
	if ( ! -e $OldChk ) {
		print STDERR <<END_OF_ERROR_MESSAGE;

The checkpoint file specified in the \%chk= line in $OldOut, which is:
$OldChk
does not exist.
Please check and try again.
I haven't touched the original input file @coms.

END_OF_ERROR_MESSAGE
		die;
	}
}

foreach my $com ( @coms ) {
	my $com_abs = abs_path($com);
	my ($com_bname, $com_path, $com_sfx) = fileparse($com_abs, ('.com', '.gjf'));
	if ( ! $com_sfx ) {
		print BOLD RED "Skipped ";
		print $com;
		print BOLD RED " not a .com or .gjf file\n";
		next
	}

	( my $chk_dir = dirname($com_abs) ) =~ s/home/scratch/;

	my $com_fh_r;
	my @com_lines;
	if ( ! open $com_fh_r, '<', $com_abs ) {
		print BOLD RED "Error opening ";
		print $com_abs;
		print BOLD RED " for read: $!\n";
		next
	} else {
		@com_lines = <$com_fh_r>;
		close $com_fh_r;
	}
	
	make_path( $chk_dir, { verbose => $verbose } );

	my @com_lines_filtered = 	map  { /^#/ ? keywords_edited_line( $_ ) : $_ }
					map  { /sol(?:vent|ven|ve|v)?/i ? solvent_edited_line( $_ ) : $_ }
					grep {	$_ !~ /^%mem=/i }
					grep {	$_ !~ /^%(?:old)?chk=/i }
					grep {	$_ !~ /^%nproc=/i }
					grep {	$_ !~ /^%lindaworkers=/i }
					@com_lines;

	if ( $OldChk ) {
		if ( ! $OldMultiplicity ) {
			print STDERR <<END_OF_WARNING;

I couldn't find the Charge and Multiplicity from the output file $OldOut
Please supply the charge and the multiplicity in your input file $com manually.

END_OF_WARNING
		} else {
			@com_lines_filtered = map { s/^\s*C\s+M$/$OldCharge $OldMultiplicity/i; $_ } @com_lines_filtered;
		}
	}
	
	my $chk_line = '%chk='.$chk_dir.'/'.$com_bname.'.chk'."\n".'%mem='.$memory.'MB'."\n";
	unshift @com_lines_filtered, $chk_line;
	@com_lines_filtered = map { /^--link1--$/i ?
				    $_ = '--link1--'."\n".$chk_line :
				    $_;
				  } @com_lines_filtered;
	
	if ( $OldChk ) {
		my $OldChkLine = '%OldChk='.$OldChk."\n";
		unshift @com_lines_filtered, $OldChkLine;
	}

	my $route_line_has_error = TestRT::test_route_line( $com_abs, \@com_lines_filtered );
	if ( $route_line_has_error ) {
		print BOLD RED "Skipped ";
		print $com;
		print BOLD RED " due to route-line syntax error\n";
		next
	}

	my $com_fh_w;
	if ( ! open $com_fh_w, '>', $com_abs ) {
		print "Error writing to $com_abs: $!\n";
		next
	}
	print $com_fh_w @com_lines_filtered;
	print $com_fh_w "\n";

}

sub print_usage {
	print <<END_OF_USAGE;
	
	Usage: $0 -i $ENV{USER}.com ( (-memory|-m)[=1024] ) (-o <.out file|.log file>)
	       $0 --lookup <solvent name|solvent abbreviation>
	
	Specify the .com file by the -i flag (obligatory).
	Specify the requested memory by the -m flag. Memory defaults to @{[ DEFAULT_MEMORY ]} MB.
	If you have an .out or .log file whose .chk file you want to reuse via a \%OldChk= line,
	    specify the .out or .log file by the -o flag.
	Use the --lookup flag to look up a solvent name or abbreviation.	

END_OF_USAGE
	exit;
}

sub lookup_solvent_abbreviations {
	my $input = shift;
	my %solv = Solvents::abbreviations();
	my ( @abbrs, @fulls );
	while ( my ( $abbr, $full_name ) = each %solv ) { 
		push @abbrs, $abbr if uc $input eq uc $full_name;
		push @fulls, $full_name if uc $input eq uc $abbr;
	} 
	return ( \@abbrs, \@fulls );
}

sub keywords_edited_line {
	my $line = shift;
	if ( $line =~ /^!/ ) {
	} else {
		$line =~ s/\bfreq(?![= ])/freq=noraman/i ;
		$line =~ s/\bempdis=/EmpiricalDispersion=/i  ;
		$line =~ s/\bEmpiricalDispersion=GD3BJ\b/EmpiricalDispersion=GD3BJ/i;
		$line =~ s/\bD3(?!0|Zero)\b/EmpiricalDispersion=GD3BJ/i;
		$line =~ s/\bD3(?:0|Zero)\b/EmpiricalDispersion=GD3/i;
		$line =~ s/\bD2\b/EmpiricalDispersion=GD2/i;
		$line =~ s/\bDF\b/DenFit/i;
	}
	return $line;
}

sub solvent_edited_line {
	my $line = shift;
	my %solv = Solvents::abbreviations();
	if ( $line =~ /^!/ ) {
		return $line;
	} else {
		while ( my ( $abbr, $full_name ) = each %solv ) {
			if ( $line =~ /sol(?:vent|ven|ve|v)?=$full_name/i ) { return $line; }
			if ( $line =~ s/(sol(?:vent|ven|ve|v)?\s*=\s*)($abbr)/$1$full_name/i ) {
				print ">>>\tReplaced solvent abbreviation $2 by $full_name\n";
				return $line;
			}
		}
		return $line;
	}
}

sub parse_for_ccmm {
	my $out = shift;
	open my $fh, '<', $out;
	my ( $charge, $multiplicity, $chk_line, @route_lines ) ;
	my $route_line;
	LINE: while ( <$fh> ) {
		state $reading_chk_lines;
		state $reading_route_lines;
		if ( /Charge = +(-?\d+) Multiplicity = +(\d+)/ && ! defined $charge ) {
			( $charge, $multiplicity ) = ( $1, $2 );
			print ">>>\tFound Charge = $1, Multiplicity = $2 in output file $out\n";
			next LINE;
		}
		if ( $reading_chk_lines ) {
			$chk_line .= $_;
			if ( length $_ < 82 || $_ !~ m'/' ||
				/\.chk$/ || $_ =~ m'=' ) 
			{
				undef $reading_chk_lines;
				next LINE;
			}
		}
		if ( /^ \%chk=/ && ! $chk_line ) {
			$chk_line .= $_;
			if ( length $_ == 82 ) {
				$reading_chk_lines = 1;
				next LINE;
			}
		}
		if ( /^ #/ ) { $reading_route_lines = 1; }
		if ( /--------------------------------/ ) {
			undef $reading_route_lines;
			push @route_lines, $route_line if $route_line;
			undef $route_line;
		}
		if ( $reading_route_lines ) {
			s/^\s+//; chomp; $route_line .= $_;
		}
	}
	if ( $chk_line ) {
		$chk_line =~ s/\s+//g;
		$chk_line =~ s'%chk='';
		$chk_line =~ s/(?<!\.chk)$/.chk/;
	}
	return ( $charge, $multiplicity, $chk_line, \@route_lines );
}
