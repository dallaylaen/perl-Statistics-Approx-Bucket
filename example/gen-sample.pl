#!/usr/bin/env perl

# This is NOT an example.
# It is a script for generating random samples of needed shape
# See $0 --help

use strict;
use warnings;

# math functions and known distributions
my @func    = qw(exp log sin cos sqrt abs),
my @distr   = qw(Normal Exp Bernoulli Uniform Dice);
my $re_num  = qr/(?:[-+]?(?:\d+\.?\d*|\.\d+)(?:[Ee][-+]?\d+)?)/;
my $white   = join "|", @func, @distr, $re_num, '[-+/*(),]', '\s+';
$white   = qr/(?:$white)/;

# Usage
if (!@ARGV or grep { $_ eq '--help' } @ARGV) {
	print STDERR <<"USAGE";
Usage: $0 [n1 formula1] [n2 formula2] ...
Output n1 random numbers distributed as formula1, etc
Formula may include: numbers, arightmetic operations and parens;
    standard functions: @func;
    and known random distributions:
	Normal(mean,deviation),
	Exp(mean),
	Bernoulli(probability),
	Uniform(lower,upper),
	Dice(n),
USAGE
	exit 1;
};


my @todo;
while (@ARGV) {
	my $n = shift;
	if ($n !~ /^\d+$/) {
		die "Random var count must be a positive integer. See $0 --help";
	};

	my $expr = shift;
	if (!defined $expr) {
		die "Odd number of arguments, see $0 --help";
	};
	if ($expr !~ /\S/) {
		die "Random var formula must be nonempty, see $0 --help";
	};
	$expr =~ /^$white+$/
		or die "Random var formula contains non-whitelisted characters. See $0 --help";

	my $code = eval "sub { $expr; };";
	if ($@) {
		die "Random var formula didn't compile: $@";
	};

	push @todo, [$code, $n];
};

# do the job
foreach (@todo) {
	while ($_->[1] --> 0) {
		print $_->[0]->(), "\n";
	};
};

#########

# TODO could cache one more point, see Box-Muller transform
sub Normal {
	return $_[0] + $_[1] * sin(2*3.1415926539*rand()) * sqrt(-2*log(rand));
};

# toss coin
sub Bernoulli {
	return rand() < $_[0] ? 1 : 0;
};

sub Uniform {
	return $_[0] + rand() * ($_[1] - $_[0]);
};

sub Exp {
	return -$_[0] * log rand();
};

sub Dice {
	return int ($_[0] * rand()) + 1;
};
