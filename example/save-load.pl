#!/usr/bin/env perl

# summary.pl with generalized printf-like option and load/save capability

use warnings;
use strict;
use JSON::XS;
use Getopt::Long;

# always want the local module version
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Statistics::Descriptive::LogScale;

# We're gonna deal with numbers. Probably in sci notation.
my $re_num = qr/(?:[-+]?(?:\d+\.?\d*|\.\d+)(?:[Ee][-+]?\d+)?)/;

# Get options
my ($load, $save, $noread, $format);
my %param;
GetOptions (
	"f|format=s" => \$format,
	"n" => \$noread,
	"l=s" => \$load,
	"s=s" => \$save,
	"a=s" => sub { $load = $_[1]; $save = $_[1]; },
	"b|base|log-base=s" => \$param{base},
	"w|width|linear-width=s" => \$param{linear_width},
	"help" => \&usage,
) or die "Bad options. See $0 --help for usage\n";
die "No data source: -n given, but no -l. See $0 --help for usage\n"
	if $noread and !defined $load;

sub usage {
	print <<"USAGE";
Usage: $0 [options] [file ...]
Read data from STDIN, load/save in JSON format, print summary
Options may include:
    data source:
    -l <file> - load data from JS file
    -s <file> - save data to JS file
    -a <file> - load, then save
    -n - don't read STDIN, just load
    storage:
    -b <n> - bin base for data storage. If given, -l only loads data points.
    -w <n> - minimal bin width in storage. If given, -l only loads data points.
    summary format:
    -f <printf-like expr> - print summary
    The expression MAY contain placeholders in form %<options><X>(<n>)
    Options are the same as in printf %f, i.e. %[-][+][0][n].[n]
    X may be:
    m - min   M - max   a - average   d - standard deviation   n - count
    p(n) - nth percentile   q(n) - nth quartile
    P(n) - probability of value being less than n
USAGE
	exit 1;
};

# configure storage, load data
my $stat;
if (!defined $load or scalar keys %param) {
	$stat = Statistics::Descriptive::LogScale->new(%param);
};
if (defined $load) {
	$stat = load_file($stat, $load);
};

# read data, if needed
unless ($noread) {
	while (<>) {
		$stat->add_data( /($re_num)/g );
	};
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
		# placeholders without parameters
		n => 'count',
		m => 'min',
		M => 'max',
		a => 'mean',
		d => 'std_dev',
		# placeholders with 1 parameter
		q => 'quantile?',
		p => 'percentile?',
		P => 'cdf?',
	);
	my $re_format = join "|", keys %format;
	$re_format = qr((?:$re_format));

	# FIXME this accepts %m(5), then dies - UGLY
	$format =~ s/\\n/\n/g;
	$format =~ s <%([0-9.\-+ #]*)($re_format)(?:\(($re_num)?\)){0,1}>
		< sprintf "%$1f", _dispatch($stat, $format{$2}, $3) >ge;
	return $format;
};

sub _dispatch {
	my ($obj, $method, $arg) = @_;

	if ($method =~ s/\?$//) {
		die "Missing argument in method $method" if !defined $arg;
	} else {
		die "Extra argument in method $method" if defined $arg;
	};
	my $result = $obj->$method($arg);

	# work around S::D::Full's convention that "-inf == undef"
	$result = -9**9**9
		if ($method eq 'percentile' and !defined $result);
	return $result;
};

sub load_file {
	my ($stat, $file) = @_;

	open (my $fd, "<", $file)
		or die "Failed to r-open $file: $!";
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

	open (my $fd, ">", $file)
		or die "Failed to w-open $file: $!";
	local $\;
	print $fd encode_json($stat->TO_JSON)
		or die "Failed to write to $file: $!";
	close $fd
		or die "Failed to close $file: $!";

	return $stat;
};
