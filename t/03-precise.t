#!/usr/bin/perl -w

use strict;
use Test::More tests => 13;

use Statistics::Approx::Bucket;

my $stat = Statistics::Approx::Bucket->new( floor => 1, base => 2);

$stat->add_data(-2, 0, 0, 4, 8);

is ($stat->count, 5, "count");
is ($stat->mean, 2, "mean");
is ($stat->percentile(50), 0, "median");
is ($stat->sumsq, 84, "sumsq");
is ($stat->min, -2, "min");
is ($stat->max, 8, "max");

my $hash = $stat->get_data_hash;
is_deeply( $hash, { -2 => 1, 0 => 2, 4=>1, 8=>1 }, "as_hash" );

my $stat2 = Statistics::Approx::Bucket->new( floor => 1, base => 2);
$stat2->add_data_hash($hash);

foreach my $method (qw(count mean sumsq min max)) {
	is ($stat2->$method, $stat->$method, "data round trip: $method");
};
is_deeply($stat2->get_data_hash, $hash, "data round trip: hash");
