#!/usr/bin/env perl

use strict;
use warnings;
use File::Copy;
use Cwd 'abs_path';
use 5.10.1; # system perl

say "This script will install addchk.pl and associated files on Hoffman2";
say "Please enter the directory in which you would like to save this script:";

chomp( my $lib_path = <STDIN> );

$lib_path = abs_path( $lib_path );

if ( ! -e $lib_path ) {
	die <<HEREDOC
$lib_path doesn't exist. Please do:

mkdir -p $lib_path

and try again.

Exiting.
HEREDOC
} 

$lib_path =~ s/\/+$//;

my %file_paths = (
	'addchk_perl5.10.pl' => $lib_path.'/addchk.pl',
	'testrt_perl5.10.pl' => $lib_path.'/testrt.pm',
	'solvent_abbr.pm'    => $lib_path.'/solvent_abbr.pm',
);

foreach ( keys %file_paths ) {
	move( $_ => $file_paths{$_} ) or die "Copying of $_ failed: $!\n";
}

open my $fh, '<', $lib_path.'/addchk.pl' or die "Reading of $lib_path/addchk.pl failed: $!\n";
open my $fh_c, '>', $lib_path.'/addchk.pl_' or die "Writing of temporary file $lib_path.'/addchk.pl_' failed: $!\n";

while (<$fh>) {
	s/^use lib \"\$ENV\{HOME\}\/bin\"/use lib "$lib_path"/;
	print $fh_c $_;
}
close $fh;
close $fh_c;

move( $lib_path.'/addchk.pl_' => $lib_path.'/addchk.pl' ) or die "Problem updating $lib_path.'/addchk.pl': $!\n";

chmod 0755, $lib_path.'/addchk.pl';

print "Testing the addchk.pl script\n";

print `$lib_path/addchk.pl`;
