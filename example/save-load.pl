#!/usr/bin/env perl

# summary.pl with generalized printf-like option and load/save capability

use warnings;
use strict;
use JSON::XS;
use Getopt::Long;
use Data::Dumper;

# always want the local module version
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Statistics::Descriptive::LogScale;

# We're gonna deal with numbers. Probably in sci notation.
my $re_num = qr/(?:[-+]?(?:\d+\.?\d*|\.\d+)(?:[Ee][-+]?\d+)?)/;

# Get options
my (@load, $save, $noread, $pairs, $format);
my %param;
my %cut;
GetOptions (
	"f|format=s" => \$format,
	"summary" => sub { $format = default_format() },
	"n" => \$noread,
	"p|read-pairs" => \$pairs,
	"l|load=s" => \@load,
	"s|save=s" => \$save,
	"a|append=s" => sub { unshift @load, $_[1]; $save = $_[1]; },
	"min=s" => \$cut{min},
	"max=s" => \$cut{max},
	"ltrim=s" => \$cut{ltrim},
	"utrim=s" => \$cut{utrim},
	"b|base|log-base=s" => \$param{base},
	"w|width|linear-width=s" => \$param{linear_width},
	"help" => \&usage,
) or die "Bad options. See $0 --help for usage\n";
die "No data source: -n given, but no -l. See $0 --help for usage\n"
	if $noread and !@load;

sub usage {
	print <<"USAGE";
Usage: $0 [options] [file ...]
Read points from STDIN, load/save in JSON format, print summary.
Options may include:
    Data source:
    -l <file> - load data from JS file. More than one -l may be given.
    -s <file> - save data to JS file
    -a <file> - load, then save
    -n - don't read STDIN, just load
    -p - read one (point, count) pair per STDIN line.
    Storage:
    -b <1.nn> - bin base for data storage. If given, -l only loads data points.
    -w <n> - minimal bin width in storage. If given, -l only loads data points.
    --min , --max - trim data before processing.
    --ltrim, --utrim - trim that % of data from lower/upper end.
    Summary format:
    -f <printf-like expr> - print summary
    The expression MAY contain placeholders in form %<options><X>(<n>)
    Options are the same as in printf %f, i.e. %[-][+][0][n].[n]
    X may be:
    m - min   M - max   a - average   d - standard deviation   n - count
    s - skeweness   k - kurtosis
    p(n) - nth percentile   q(n) - nth quartile
    P(n) - probability of value being less than n
    e(n) - nth central momEnt   E(n) - nth standardized momEnt
USAGE
	exit 1;
};

# This is actually a constant
sub default_format {
	return <<"SUMMARY"
count : %15.0n;      min/max: %m .. %M
median: %15p(50); mean/std_dev: %a +- %d
     skewness: %s; kurtosis: %k
SUMMARY
	. join "", map { sprintf ("%5.1f%%%%: %%15p(%0.1f)\n", $_, $_) }
		 0.5, 1, 5, 10, 25, 50, 75, 90, 95, 99.5;
};

# configure storage, load data
my $stat;
if (!@load or scalar keys %param) {
	$stat = Statistics::Descriptive::LogScale->new(%param);
};
if (@load) {
	$stat = load_file($stat, $_) for @load;
};

# read data, if needed
unless ($noread) {
	if ($pairs) {
		while (<>) {
			my ($point, $count) = /($re_num)/g;
			next unless $count;
			$stat->add_data_hash( { $point => $count } );
		};
	} else {
		while (<>) {
			$stat->add_data( /($re_num)/g );
		};
	};
};

if (%cut) {
	$stat = $stat->clone( %cut );
};

# print summary
# TODO draw image as well
if (defined $format) {
	print format_summary( $stat, $format );
};

# save data. Ignore if no data was read.
if (defined $save && !$noread) {
	save_file($stat, $save);
};

# all folks - main ends here

# FORMAT
# We'll have printf-like expression in the form "%<format><function><arg>
sub format_summary {
	my ($stat, $format) = @_;

	my %format = (
		# percent literal
		'%' => '%',
		# placeholders without parameters
		n => 'count',
		m => 'min',
		M => 'max',
		a => 'mean',
		d => 'std_dev',
		s => 'skewness',
		k => 'kurtosis',
		# placeholders with 1 parameter
		q => 'quantile?',
		p => 'percentile?',
		P => 'cdf?',
		e => 'central_moment?',
		E => 'std_moment?',
	);
	my $re_format = join "|", keys %format;
	$re_format = qr((?:$re_format));

	# FIXME this accepts %m(5), then dies - UGLY
	$format =~ s/\\n/\n/g;
	$format =~ s <%([0-9.\-+ #]*)($re_format)(?:\(($re_num)?\)){0,1}>
		< _dispatch($stat, $format{$2}, $1, $3) >ge;
	return $format;
};

sub _dispatch {
	my ($obj, $method, $float, $arg) = @_;

	if ($method !~ /^[a-z_]/) {
		return $method;
	};
	if ($method =~ s/\?$//) {
		die "Missing argument in method $method" if !defined $arg;
	} else {
		die "Extra argument in method $method" if defined $arg;
	};
	my $result = $obj->$method($arg);

	# work around S::D::Full's convention that "-inf == undef"
	$result = -9**9**9
		if ($method eq 'percentile' and !defined $result);
	return sprintf "%${float}f", $result;
};

sub load_file {
	my ($stat, $file) = @_;

	my $fd;
	if ($file eq '-') {
		$fd = \*STDIN;
	} else {
		open ($fd, "<", $file)
			or die "Failed to r-open $file: $!";
	};
	local $/;
	defined (my $js = <$fd>)
		or die "Failed to read from $file: $!";
	close $fd;

	my $raw = decode_json($js);
	# TODO check data thoroughly
	if ($stat) {
		$stat->add_data_hash( $raw->{data} );
	} else {
		$stat = Statistics::Descriptive::LogScale->new( %$raw );
	};

	return $stat;
};

sub save_file {
	my ($stat, $file) = @_;

	my $fd;
	if ($file eq '-') {
		$fd = \*STDOUT;
	} else {
		open ($fd, ">", $file)
			or die "Failed to w-open $file: $!";
	};
	local $\;
	print $fd encode_json($stat->TO_JSON)
		or die "Failed to write to $file: $!";
	close $fd
		or die "Failed to close $file: $!";

	return $stat;
};
