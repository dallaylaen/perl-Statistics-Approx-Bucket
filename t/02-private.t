#!/usr/bin/perl -w

use strict;
use Test::More tests => 3 + 5*6;
use Test::More;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new(floor => 0.125, base => 2);

is ($stat->_round(0.01), 0, "round(0)");
is ($stat->_round(-1), -1, "round(-1)");
is ($stat->_round(40), 32, "round(40)");

foreach (0, 0.001, 1, -1, exp 3, -11) {
	cmp_ok ($stat->_lower($_), "<=", $_, "floor< $_");
	cmp_ok ($stat->_upper($_), ">=", $_, "ceil > $_");
	cmp_ok ($stat->_lower($_), "<", $stat->_round($_), "floor<round $_");
	cmp_ok ($stat->_upper($_), ">", $stat->_round($_), "ceil >round $_");

	if ($stat->_round($_) > 0) {
		is ($stat->_upper($_) / $stat->_lower($_),
			1+$stat->bucket_width, "ceil/floor($_)");
	} elsif ( $stat->_round($_) == 0) {
		is ($stat->_upper($_) / $stat->_lower($_),
			-1, "ceil/floor($_)");
	} else {
		is ($stat->_lower($_) / $stat->_upper($_),
			1+$stat->bucket_width, "ceil/floor($_)");
	};
};
