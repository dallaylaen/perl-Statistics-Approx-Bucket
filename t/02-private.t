#!/usr/bin/perl -w

use strict;
use Test::More tests => 5;

use Statistics::Approx::Bucket;

my $stat = Statistics::Approx::Bucket->new(floor => 1, base => 2);

is ($stat->_power(0),   0, "power(0)");
is ($stat->_power(1),   1, "power(1)");
is ($stat->_power(4),   8, "power(+)");
is ($stat->_power(-1), -1, "power(-)");
is ($stat->_power(-4), -8, "power(-)");
