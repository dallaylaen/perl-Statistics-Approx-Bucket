#!/usr/bin/perl -w

use strict;
use Test::More tests => 10;

use Statistics::Approx::Bucket;

my $stat = Statistics::Approx::Bucket->new(floor => 0.125, base => 2);

is ($stat->_power(0),   0, "power(0)");
is ($stat->_power(4),   1, "power(1)");
is ($stat->_power(7),   8, "power(+)");
is ($stat->_power(-4), -1, "power(-)");
is ($stat->_power(-7), -8, "power(-)");

is ($stat->_power( $stat->_index( $_ ) ), $_, "bucket/power round trip $_")
	for qw(0 1 8 -1 -8);

__END__
# These functions not yet done!

is ($stat->_lower($_+1), $stat->_upper($_), "lower[$_+1] == upper[$_]")
	for -3..3;

ok ($stat->_lower($_) < $stat->_power($_), "lower < center ($_)")
	for -3..3;
ok ($stat->_upper($_) > $stat->_power($_), "upper > center ($_)")
	for -3..3;


