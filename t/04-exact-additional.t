#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;
use YAML;

use Statistics::Approx::Bucket;

my $stat = Statistics::Approx::Bucket->new (floor => 0.5, base => 2);

$stat->add_data(1, 2, 4, 8, 16);

# note "log 2 = ".log 2;
# note Dump($stat);

is ($stat->mean, 6.2, "mean (this tests nothing new)");
is ($stat->geometric_mean, 4, "geometric");
is ($stat->harmonic_mean, 5/(2-1/16), "harmonic");

is ($stat->quantile(0), 1, "Q0");
is ($stat->quantile(1), 2, "Q1");
is ($stat->quantile(2), 4, "Q2");
is ($stat->quantile(3), 8, "Q3");
is ($stat->quantile(4), 16, "Q4");
