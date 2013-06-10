#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Statistics::Approx::Bucket' ) || print "Bail out!\n";
}

diag( "Testing Statistics::Approx::Bucket $Statistics::Approx::Bucket::VERSION, Perl $], $^X" );
