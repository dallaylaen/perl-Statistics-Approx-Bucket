use 5.006;
use strict;
use warnings;

package Statistics::Approx::Bucket;

=head1 NAME

Statistics::Approx::Bucket - approximate statistical distribution class
using logarithmic buckets to store data.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Statistics::Approx::Bucket;
    my $stat = Statistics::Approx::Bucket->new (floor => 1E-6, );

=head1 METHODS

=cut

use fields qw(
	pos neg zero
	base logbase floor logfloor
	total
);

=head2 new

=cut

sub new {
	my $class = shift;
	my %opt = @_;

	#

	my $self = fields::new($class);
	$self->{neg} = [];
	$self->{pos} = [];
	$self->{$_} = $opt{$_}
		for qw(base floor);
	$self->{logbase} = log $opt{base};
	$self->{logfloor} = log $opt{floor};
	return $self;
}


=head2 add_data

=cut

sub add_data {
	my $self = shift;
	foreach my $x (@_) {
		my $store = "pos";
		if ($x < 0) {
			$store = "neg";
			$x = -$x;
		};
		my $idx = int (
			(log $x - $self->{logfloor}) / $self->{logbase} + 0.5);
		if ($idx < 0) {
			$self->{zero}++;
		} else {
			$self->{$store}[$idx]++;
		};
		$self->{total}++;
	};
};

=head2 percentile

=cut

sub percentile {
	my $self = shift;
	my $x = shift;

	# assert 0<=$x<=100

	my $need = $x * $self->{total} / 100;
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

sub _power {
	my $self = shift;
	my $i = shift;

	return 0 if $i == 0;
	my $sign = $i > 0 ? 1 : -1;
	$i = abs($i)-1;
	return $sign * exp ($self->{logfloor} + $self->{logbase} * $i);
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


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Statistics::Approx::Bucket
