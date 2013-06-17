#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;

use Statistics::Approx::Bucket;

my $stat = Statistics::Approx::Bucket->new(floor => 0.125, base => 1.01);

cmp_ok ($stat->zero_threshold, "<=", 0.125, "0 < real floor <= floor");
cmp_ok ($stat->zero_threshold, ">", 0, "0 < real floor <= floor");

is ($stat->bucket_width, 0.01, "Bucket width as expected");

$stat->add_data($stat->zero_threshold / 2);
$stat->add_data(-$stat->zero_threshold / 2);
my $raw = $stat->get_data_hash;
is_deeply ($raw, { 0 => 2 }, "2 subzero values => 0,0")
	or diag "Returned raw data = ".explain($raw);


