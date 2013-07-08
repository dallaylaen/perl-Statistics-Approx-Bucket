#!/usr/bin/perl -w

use strict;
use GD::Simple;
use Getopt::Long;

# always prefer local version of module
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Statistics::Descriptive::LogScale;

my %opt = (width => 600, height => 200, trim => 0);

# Don't require module just in case
GetOptions (
	'base=s' => \$opt{base},
	'floor=s' => \$opt{zero},
	'width=s' => \$opt{width},
	'height=s' => \$opt{height},
	'ltrim=s' => \$opt{ltrim},
	'utrim=s' => \$opt{utrim},
	'min=s' => \$opt{min},
	'max=s' => \$opt{max},
	'help' => sub {
		print "Usage: $0 [--base <1+small o> --floor <nnn>] pic.png\n";
		print "Read numbers from STDIN, output histogram\n";
		print "Number of sections = n (default 20)";
		exit 2;
	},
);

# Where to write the pic
my $out = shift;

defined $out or die "No output file given";
my $fd;
if ($out eq '-') {
	$fd = \*STDOUT;
} else {
	open ($fd, ">", $out) or die "Failed to open $out: $!";
};

my $stat = Statistics::Descriptive::LogScale->new(
	base => $opt{base}, zero_thresh => $opt{zero});

while (<STDIN>) {
	$stat->add_data(/(-?\d+(?:\.\d*)?)/g);
};

my ($width, $height) = @opt{"width", "height"};

my $hist = $stat->histogram( %opt, count => $width);

my $trimmer = Statistics::Descriptive::LogScale->new;
$trimmer->add_data(map { $_->[0]} @$hist);

my $max = $trimmer->percentile(99)/0.7;
$_->[0] /= $max for @$hist;

# warn "hist = @hist\n";
# draw!
my $gd = GD::Simple->new($width, $height);
$gd->bgcolor('white');
$gd->clear;

my $i=0;
foreach (@$hist) {
	$gd->fgcolor( $_->[0] > 1 ? 'red' : 'orange');
	$gd->line($i, $height, $i, $height*(1-$_->[0]));
	$i++;
};

print $fd $gd->png;

