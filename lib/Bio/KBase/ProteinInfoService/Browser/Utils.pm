package Bio::KBase::ProteinInfoService::Browser::Utils;
require Exporter;

use strict;
use CGI;
use Bio::KBase::ProteinInfoService::Browser::Defaults;

use vars '$VERSION';
use vars qw($defaults);
$VERSION = 0.01;

our @ISA = qw(Exporter);
our @EXPORT =  qw(rangeInt intRange complement date unique htmlQuote htmlUnQuote baseFile);

our @months_short = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
our @months_long = qw/January February March April May June July August September October November December/;
our @weekdays_short = qw/Sun Mon Tue Wed Thu Fri Sat/;
our @weekdays_long = qw/Sunday Monday Tuesday Wednesday Thursday Friday Saturday/;
our @alpha = ( 0..9, 'a'..'f' );

# Returns a list of all elements in set1 that are not in set2
sub setSubtract
{
	my $set1 = shift;
	my $set2 = shift;
	my @diff = ();
	my %set2Map = ();
	foreach my $e ( @{$set2} )
	{
		$set2Map{$e} = 1;
	}
	foreach my $e ( @{$set1} )
	{
		push( @diff, $e )
			if ( !exists( $set2Map{$e} ) );
	}

	return wantarray ?
		@diff :
		\@diff;
}

sub baseFile
{
	my $file = shift;
	my $sanitize = shift;
	$file =~ s/\\/\//g;
	my $base = (split(/\//, $file))[-1];
	if ( defined($sanitize) && $sanitize )
	{
		$base =~ tr/ \t\r\n~`<>/_/;
	}
	return $base;
}

sub htmlQuote
{
	my $str = shift;
	$str =~ s/</&lt;/g;
	$str =~ s/>/&gt;/g;
	$str =~ s/"/&quot;/g;
	return $str;
}

sub htmlUnQuote
{
	my $str = shift;
	$str =~ s/&lt;/</g;
	$str =~ s/&gt;/>/g;
	$str =~ s/&quot;/"/g;
	return $str;
}

sub unique
{
	my @data = @_;
	my %dataHash = ();
	my @uData = ();

	foreach my $d ( @data )
	{
		if ( !exists($dataHash{$d}) )
		{
			push( @uData, $d );
			$dataHash{$d} = 1;
		}
	}

	return @uData;
}

#
# Handy-dandy multi-purpose formatted date function
#
# a - "am" or "pm"
# A - "AM" or "PM"
# B - <unsupported>
# d - day of the month, 2 digits with leading zeros: 01 to 31
# D - day of the week, 3 letters: Sun to Sat
# F - month, long: January to December
# g - hour, 12-hour format without leading zeros: 1 to 12
# G - hour, 24-hour format without leading zeros: 0 to 23
# h - hour, 12-hour format with leading zeros: 01 to 12
# H - hour, 24-hour format with leading zeros: 00 to 23
# i - minutes, with leading zeros: 00 to 59
# I - 1 if Daylight Savings Time, 0 otherwise.
# j - day of the month, without leading zeros: 1 to 31
# l - day of the week, long: Sunday to Saturday
# L - <unsupported>
# m - month, with leading zeros: 01 to 12
# M - month, 3 letters: Jan to Dec
# n - month, without leading zeros: 1 to 12
# O - <unsupported>
# r - <unsupported>
# s - seconds, with leading zeros: 00 to 59
# S - <unsupported>
# t - <unsupported>
# T - <unsupported>
# U - seconds since last epoch
# w - day of the week, numeric: 0 (Sunday) to 6 (Saturday)
# W - <unsupported>
# Y - year, 4 digits, i.e. "2002"
# y - year, 2 digits, i.e. "02"
# z - day of the year: 0 to 365
# Z - <unsupported>
#
sub date
{
	my $fmt = shift;
	my $ts = shift;
	my $result = "";
	my @fmtstr = split(//, $fmt);
	my $i;
	my @lt;
	my %vals;

	if ( !defined($ts) )
	{
		$ts = time();
	}

	@lt = localtime( $ts );

	# Compute %vals
	if ( $lt[2] < 12 )
	{
		$vals{a} = "am";
		$vals{A} = "AM";
	} else {
		$vals{a} = "pm";
		$vals{A} = "PM";
	}

	$vals{d} = sprintf( "%02d", $lt[3] );
	$vals{D} = $weekdays_short[ $lt[6] ];
	$vals{F} = $months_long[ $lt[4] ];
	if ( $lt[2] % 12 == 0 )
	{
		$vals{g} = 12;
		$vals{h} = 12;
	} else {
		$vals{g} = $lt[2] % 12;
		$vals{h} = sprintf( "%02d", $vals{g} );
	}
	$vals{G} = $lt[2];
	$vals{H} = sprintf( "%02d", $lt[2] );
	$vals{i} = sprintf( "%02d", $lt[1] );
	$vals{I} = $lt[8];
	$vals{j} = $lt[3];
	$vals{l} = $weekdays_long[ $lt[6] ];
	$vals{m} = sprintf( "%02d", $lt[4] + 1 );
	$vals{M} = $months_short[ $lt[4] ];
	$vals{n} = $lt[4] + 1;
	$vals{s} = sprintf( "%02d", $lt[0] );
	$vals{U} = $ts;
	$vals{w} = $lt[6];
	$vals{Y} = $lt[5] + 1900;
	$vals{y} = $lt[5];
	$vals{z} = $lt[7];

	for ($i = 0; $i <= $#fmtstr; $i++)
	{
		my $c = $fmtstr[$i];
		if ( $c =~ /^[A-Za-z]$/ )
		{
			$result .= $vals{$c};
		} else {
			$result .= $c;
		}
	}

	return $result;
}

sub rangeInt($)
{
	my $range = shift;

	return 0
		if ( !defined($range) );
	return $range
		if ( $range =~ /^\d+$/ );

	if ( $range =~ /^(\d+(\.\d+)?)\s*(\w)/ )
	{
		my $val = $1;
		my $unit = lc( $3 );

		if ( $unit eq 'k' )
		{
			$val *= 1000;
		} elsif ( $unit eq 'm' )
		{
			$val *= 1000000;
		} elsif ( $unit eq 'g' )
		{
			$val *= 1000000000;
		} elsif ( $unit eq 't' )
		{
			$val *= 1000000000000;
		}

		$val = int($val);
		return $val;
	}

	return 0;
}

sub intRange($)
{
	my $val = shift;
	return $val	if (int($val) == 0);

	my $absVal = ($val < 0) ? $val * -1 : $val;
	if ( $absVal < 1000 )
	{
		return $val . " bp";
	} elsif ( $absVal < 1000000 )
	{
		$val /= 1000.0;
		return sprintf( "%01.2f Kb", $val );
	} elsif ( $absVal < 1000000000 )
	{
		$val /= 1000000.0;
		return sprintf( "%01.2f Mb", $val );
	} else
	{
		$val /= 1000000000.0;
		return sprintf( "%01.2f Gb", $val );
	}
}

sub complement($)
{
	my $seq = shift;
	$seq =~ tr/ATCGatcg/TAGCtagc/;
	return $seq;
}

sub randHex
{
	my $len = shift;
	$len = 20
		if ( !defined($len) );
	my $rand = "";

	my $numAlpha = scalar( @alpha );
	for ( my $i = 0; $i < $len; $i++ )
	{
		$rand .= $alpha[ int( rand( $numAlpha ) ) ];
	}

	return $rand;
}

1;


