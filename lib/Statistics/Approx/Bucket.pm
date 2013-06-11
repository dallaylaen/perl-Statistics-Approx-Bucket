use 5.006;
use strict;
use warnings;

package Statistics::Approx::Bucket;

=head1 NAME

Statistics::Approx::Bucket - approximate statistical distribution class
using logarithmic buckets to store data.

=head1 VERSION

Version 0.02

=cut

our $VERSION = 0.0204;

=head1 SYNOPSIS

    use Statistics::Approx::Bucket;
    my $stat = Statistics::Approx::Bucket->new (floor => 1E-6, );

=head1 DESCRIPTION

This module aims at providing some advanced statistical functions without
storing all data in memory, at the cost of introducing fixed relative error.

Data is represented by a set of logarithmic buckets only storing counters.

=head1 METHODS

=cut

use Carp;

use fields qw(
	pos neg zero
	base logbase floor logfloor
	count
);

=head2 new( %options )

%options must include:

=over

=item * floor - values with absolute value less than this are considered zero;

=item * base - ratio of adjacent buckets.

=back

=cut

sub new {
	my $class = shift;
	my %opt = @_;

	# TODO handle %opt somehow

	my $self = fields::new($class);
	$self->{$_} = $opt{$_}
		for qw(base floor);
	$self->{logbase} = log $opt{base};
	$self->{logfloor} = log $opt{floor};
	$self->clear;
	return $self;
};

=head2 clear()

Destroy all stored data.

=cut

sub clear {
	my $self = shift;
	$self->{neg} = [];
	$self->{zero} = 0;
	$self->{pos} = [];
	$self->{count} = 0;
	return $self;
};

=head2 add_data( @data )

Add numbers to the data pool.

=cut

sub add_data {
	my $self = shift;
	foreach my $x (@_) {
		$self->{count}++;

		my $bucket = $self->_bucket($x);
		$$bucket++;
	};
};

=head2 add_data_hash

=cut

sub add_data_hash {
	my $self = shift;
	my $hash = shift;

	foreach (keys %$hash) {
		my $bucket = $self->_bucket( $_ );
		$$bucket += $hash->{$_};
		$self->{count} += $hash->{$_};
	};
};

=head2 get_data_hash()

Return distribution hashref {value => number of occurances}.

=cut

sub get_data_hash {
	my $self = shift;

	my $hash = {};
	for (my $i = @{ $self->{neg} }; $i-->0; ) {
		next unless $self->{neg}[$i];
		$hash->{ $self->_power(-1-$i) } = $self->{neg}[$i];
	};
	if ($self->{zero}) {
		$hash->{ 0 } = $self->{zero};
	};
	for (my $i = 0; $i < @{ $self->{pos} }; $i++ ) {
		next unless $self->{pos}[$i];
		$hash->{ $self->_power(+1+$i) } = $self->{pos}[$i];
	};
	return $hash;

};

=head2 count

Return number of data points.

=cut

sub count {
	my $self = shift;
	return $self->{count};
};

=head2 sum()

Return sum of all data points.

=cut

sub sum {
	my $self = shift;
	return $self->sum_func(sub { $_[0] });
};

=head2 sumsq()

Return sum of squares of all datapoints.

=cut

sub sumsq {
	my $self = shift;
	return $self->sum_func(sub { $_[0] * $_[0] });
};

=head2 mean()

Return mean, which is sum()/count().

=cut

sub mean {
	my $self = shift;
	return $self->{count} ? $self->sum / $self->{count} : undef;
};

=head2 variance()

Return data variance.

=cut

sub variance {
	my $self = shift;

	# This part is stolen from Statistics::Descriptive
	my $div = @_ ? 0 : 1;
	if ($self->{count} < 1 + $div) {
		return 0;
	}

	my $var = $self->sumsq - $self->sum**2 / $self->{count};
	return $var < 0 ? 0 : $var / ( $self->{count} - $div );
};

=head2 standard_deviation()

=head2 std_dev()

Return standard deviation.

=cut

sub standard_deviation {
	# This part is stolen from Statistics::Descriptive
	my $self = shift;
	return if (!$self->count());
	return sqrt($self->variance());
};

BEGIN {
	no warnings 'once'; ## no critic
	*std_dev = \&standard_deviation;
};

=head2 min()

=head2 max()

Values of minimal and maximal buckets.

=cut

sub min {
	my $self = shift;
	for ( my $i = @{ $self->{neg} }; $i-->0; ) {
		$self->{neg}[$i] and return $self->_power(-1-$i);
	};
	$self->{zero} and return 0;
	for ( my $i = 0; $i<@{ $self->{pos} }; $i++ ) {
		$self->{pos}[$i] and return $self->_power(+1+$i);
	};
};

sub max {
	my $self = shift;
	for ( my $i = @{ $self->{pos} }; $i-->0; ) {
		$self->{pos}[$i] and return $self->_power(+1+$i);
	};
	$self->{zero} and return 0;
	for ( my $i = 0; $i<@{ $self->{neg} }; $i++ ) {
		$self->{neg}[$i] and return $self->_power(-1-$i);
	};
};

=head2 sample_range()

Return sample range of the dataset, i.e. max() - min().

=cut

sub sample_range {
	my $self = shift;
	return $self->max - $self->min;
};

=head2 percentile( $n )

Find $n-th percentile, i.e. a value below which lies $n % of the data.

0-th percentile is by definition -inf and is returned as undef
(see Statistics::Descriptive).

=cut

sub percentile {
	my $self = shift;
	my $x = shift;

	# assert 0<=$x<=100
	croak __PACKAGE__.": percentile() argument must be between 0 and 100"
		unless 0<= $x and $x <= 100;

	my $need = $x * $self->{count} / 100;
	return if $need < 1;
	my $sum = 0;
	for (my $i = @{ $self->{neg} }; $i-->0; ) {
		next unless $self->{neg}[$i];
		$sum += $self->{neg}[$i];
		return $self->_power(-1-$i) if $sum >= $need;
	};
	if ($self->{zero}) {
		$sum += $self->{zero} || 0;
		return 0 if $sum >= $need;
	};
	for (my $i = 0; $i < @{ $self->{pos} }; $i++ ) {
		next unless $self->{pos}[$i];
		$sum += $self->{pos}[$i];
		return $self->_power($i+1) if $sum >= $need;
	};
	die "Control never reaches here";
};

=head2 quantile( 0..4 )

From Statistics::Descriptive manual:

  0 => zero quartile (Q0) : minimal value
  1 => first quartile (Q1) : lower quartile = lowest cut off (25%) of data = 25th percentile
  2 => second quartile (Q2) : median = it cuts data set in half = 50th percentile
  3 => third quartile (Q3) : upper quartile = highest cut off (25%) of data, or lowest 75% = 75th percentile
  4 => fourth quartile (Q4) : maximal value

=cut

sub quantile {
	my $self = shift;
	my $t = shift;

	croak (__PACKAGE__.": quantile() argument must be one of 0..4")
		unless $t =~ /^[0-4]$/;

	$t or return $self->min;
	return $self->percentile($t * 100 / 4);
};

=head2 median()

Returns median of data. Same as percentile(50).

=cut

sub median {
	my $self = shift;
	return $self->percentile(50);
};

=head2 sum_func( $code )

Return sum of $code->($_) across all data. $code is expected to have no side
effects and only depend on its input.

=cut

sub sum_func {
	my $self = shift;
	my ($code) = @_;

	my $sum = 0;
	for (my $i = @{ $self->{neg} }; $i-->0; ) {
		next unless $self->{neg}[$i];
		$sum += $self->{neg}[$i] * $code->( $self->_power(-1-$i) );
	};
	if ($self->{zero}) {
		$sum += $self->{zero} * $code->( $self->_power(0) );
	};
	for (my $i = 0; $i < @{ $self->{pos} }; $i++ ) {
		next unless $self->{pos}[$i];
		$sum += $self->{pos}[$i] * $code->( $self->_power(+1+$i) );
	};
	return $sum;
};

sub _power {
	my $self = shift;
	my $i = shift;

	return 0 if $i == 0;
	my $sign = $i > 0 ? 1 : -1;
	$i = abs($i)-1;
	return $sign * exp ($self->{logfloor} + $self->{logbase} * $i);
};

# reverse of power.
sub _index {
	my $self = shift;
	my $x = shift;

	if (abs($x) < $self->{floor}) {
		return 0;
	};

	my $i = (log abs($x) - $self->{logfloor}) / $self->{logbase};
	$i = int($i + 1.5); # +0.5: rounding; +1: index(floor) = 1, not 0
	return $x < 0 ? -$i : $i;
};

sub _bucket {
	my $self = shift;
	my $x = shift;

	if (abs($x) < $self->{floor}) {
		return \($self->{zero});
	};

	my $i = (log abs($x) - $self->{logfloor}) / $self->{logbase};
	$i = int($i + 0.5);
	my $store = $x < 0 ? "neg" : "pos";
	return \( $self->{$store}[$i] );
};

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-approx-bucket at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Approx-Bucket>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Approx::Bucket


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Approx-Bucket>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Approx-Bucket>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Approx-Bucket>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Approx-Bucket/>

=back


=head1 ACKNOWLEDGEMENTS

This module was inspired by a talk that Andrew Aksyonoff, author of
L<Sphinx search software|http://sphinxsearch.com/>,
has given at HighLoad++ conference in Moscow, 2012.

L<Statistics::Descriptive> was and is used as reference when in doubt.
Several code snippets were shamelessly stolen from there.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Statistics::Approx::Bucket
