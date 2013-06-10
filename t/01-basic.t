#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;
use Data::Dumper;

use Statistics::Approx::Bucket;

my $stat =  Statistics::Approx::Bucket->new(floor => 1, base => 10**(1/10));

$stat->add_data(1..10);

about ($stat->percentile(0), 1, "0th % = 1");
about ($stat->percentile(100), 10, "100th = 10");
about ($stat->percentile(50), 5, "Median = 5");

# note ( Dumper( $stat ));

sub about {
	my ($got, $exp, $msg) = @_;
	my $ret = ok ( abs ( $got - $exp ) / abs ($exp) < 0.1,
		$msg . "(exp = $exp, got = $got)");
	return $ret;
};
