# DESCRIPTION

**Statistics::Descriptive::LogScale** - Memory-efficient approximate
univariate statistical analysis module.

It allows to study various properties of a one-dimentional statistical sample:
mean, variance, percentiles, moments of arbitrary power,
cumulative distribution function (i.e. probability to hit specific range) etc.

The whole sample doesn't have to be loaded into memory,
at a cost of a certain predictable relative error.
(see DATA MODEL below).
This also allows for storing the data efficiently for future analysis.

This module can be used in place of  _Statistics::Descriptive::Full_
given that exact values and remembering incoming data order are not required.

# SINOPSIS

	use strict;
	use warnings;
    use Statistics::Descriptive::LogScale;

    my $stat = Statistics::Descriptive::LogScale->new (
        base => 1.01,
        linear_width => 0.001,
    );

	while (<>) {
		$stat->add_data($_) for /(-?\d+(?:\.\d*)?)/g;
	};
    # add more data....

	printf "   minimal value: %f\n", $stat->min;
    printf "%3uth percentile: %f\n", $_*10, $stat->percentile($_*10)
		for 1..10;

# DATA MODEL

The data is divided into logarithmic intervals, or bins, i.e.
such that upper boundary/lower boundary ratio is constant across all bins.
This allows to store data spanning orders of magnitude
while maintaining a guaranteed relative precision.

For instance, the default bin ratio is 10^1/232, which is approximately 1%
and allows sorting numbers from 1 to 1000000 into like 1400 bins.

Additionally, linear approximation can be used around zero to save memory.
The incoming data is rarely absolutely precise anyway.
The threshold under which linear interpolation is used is roughly
(precision of data)/(bin ratio).
By default, data is assumed to be precise, so linear approximation is not used.

# WHY THIS MODULE

Initially it was started out as a quick and dirty performance analysis tool.
It turned out that in some cases average values do not tell that much,
as in "your service responds in 0.1 +- 10 seconds".

Another usage can be long-running and/or memory-limited applications.
It's possible to save data samples and/or send them over the network,
as well as gradually "forget" old data.

Ideally, it should become *the* tool for preliminary analysis and drawing
funny pictures until one realises they need serious stuff like R.
