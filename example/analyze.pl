#!/usr/bin/perl -w

# This is a simple script that reads numbers from STDIN
# and prints out a summary at EOF.

use strict;
use Statistics::Approx::Bucket;

my $base = 10**(1/20);
my $floor = 10**-6;

# Don't require module just in case
if ( eval { require Getopt::Long; 1; } ) {
	Getopt::Long->import;
	GetOptions (
		'base=s' => \$base,
		'floor=s' => \$floor,
		'help' => sub {
			print "usage: $0 [--base <1+small o> --floor <nnn>]";
			exit 2;
		},
	);
} else {
	@ARGV and die "Options given, but no Getopt::Long support";
};

my $stat = Statistics::Approx::Bucket->new( base => $base, floor => $floor);

while (<STDIN>) {
	$stat->add_data(/(-?\d+(?:\.\d*)?)/g);
};

print_result();

sub print_result {
	printf "Count: %u\nMean:  %f\nDisp:  %f\nMin:   %f\nMax:   %f\n",
		$stat->count, $stat->mean, $stat->std_dev,
		$stat->min, $stat->max;
	printf "Percentiles:\n";
	foreach (0.5, 1, 5, 10, 25, 50, 75, 90, 95, 99, 99.5) {
		my $x = $stat->percentile($_);
		$x = "-inf" unless defined $x;
		printf "%4.1f: %f\n", $_, $x;
	};
};

