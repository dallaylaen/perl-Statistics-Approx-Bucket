#!/usr/bin/perl -w

use strict;
use Test::More tests => 10;

use Statistics::Approx::Bucket;

my $stat = Statistics::Approx::Bucket->new(floor => 1, base => 2);

is ($stat->_power(0),   0, "power(0)");
is ($stat->_power(1),   1, "power(1)");
is ($stat->_power(4),   8, "power(+)");
is ($stat->_power(-1), -1, "power(-)");
is ($stat->_power(-4), -8, "power(-)");

is ($stat->_power( $stat->_index( $_ ) ), $_, "bucket/power round trip $_")
	for qw(0 1 8 -1 -8);
