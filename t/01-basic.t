#!/usr/bin/perl -w

use strict;
use Test::More tests => 9;
use Data::Dumper;

use Statistics::Approx::Bucket;

my $stat =  Statistics::Approx::Bucket->new(floor => 1, base => 10**(1/10));

my @data = (1..100);

$stat->add_data(@data);

is ($stat->percentile(0), undef, "0th % = -inf");
about ($stat->percentile(100/@data), 1, "10th = 1");
about ($stat->percentile(100), $data[-1], "100th = 10");
about ($stat->percentile(50), $data[@data/2], "Median = 5");

# note ( Dumper( $stat ));

# ad-hoc basic statistics
my $n;  $n  += 1     for @data;
my $s;  $s  += $_    for @data;
my $s2; $s2 += $_*$_ for @data;

my $mean = $s / $n;
my $std_dev = sqrt( $s2 / $n - $mean*$mean );

is ($stat->count, $n, "count OK");
about ($stat->sum, $s, "sum");
about ($stat->sumsq, $s2, "sumsq");
about ($stat->mean, $mean, "mean");
about ($stat->std_dev, $std_dev, "std_dev");


#######
sub about {
	my ($got, $exp, $msg) = @_;
	my $ret = ok ( abs ( $got - $exp ) / abs ($exp) < 0.1,
		$msg . "(exp = $exp, got = $got)");
	return $ret;
};
