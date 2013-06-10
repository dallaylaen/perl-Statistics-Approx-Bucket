#!/usr/bin/perl -w

use strict;
use Test::More;
use Data::Dumper;

use Statistics::Approx::Bucket;

my @samples = ([1..100], [-100..-1], [-10..12],
	[map { $_ / 10 } -15..35 ]);
plan tests => 12 * @samples;

foreach (@samples) {
	my @data = @$_;
	note "### Testing @data...";
	my $stat =  Statistics::Approx::Bucket->new(
		floor => 1, base => 10**(1/10));
	$stat->add_data(@data);
	# note ( Dumper( $stat ));

	is ($stat->percentile(0), undef, "0th % = -inf");
	about ($stat->percentile(100/@data), $data[0],
		"first finite centile = 1st val");
	about ($stat->percentile(50), $data[@data/2], "Median = middle");
	about ($stat->percentile(100), $data[-1], "100th centile = last value");
	is ($stat->max, $stat->percentile(100),
		"max value = 100th centile (exact)");
	about ($stat->min, $data[0], "min = data[0]");
	about ($stat->sample_range, $data[-1] - $data[0], "sample range");

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
};

#######
sub about {
	my ($got, $exp, $msg) = @_;
	my $ret = ok ( abs ( $got - $exp ) / abs ($exp) < 0.1,
		$msg . " (exp = $exp, got = $got)");
	return $ret;
};
