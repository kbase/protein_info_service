package Bio::KBase::ProteinInfoService::Browser::CGIParse;
require Exporter;

use strict;
use CGI;
use Bio::KBase::ProteinInfoService::Browser::Defaults;
use Bio::KBase::ProteinInfoService::Browser::Utils;

use vars '$VERSION';
use vars qw($defaults);
$VERSION = 0.01;

our @ISA = qw(Exporter);
our @EXPORT =  qw(parseCGIParameters flatBrowserParams newViewUrl paramsToForm);

sub paramsToForm
{
	my $bParams = shift;
	my $formHtml = "";

	while( my ($key, $val) = each( %{$bParams} ) )
	{
		if ( ($key ne 'data') && ($key !~ /^_/) )
		{
			$formHtml .= "<input type=\"hidden\" name=\"$key\" value=\"$val\">\n";
		}
	}

	return $formHtml;
}

sub newViewUrl
{
	my $oParams = shift;

	my %bParams = %{$oParams};
	my $newView = shift;

	# newView commands:
	# zoomin:n (zoom in n times)
	# zoomout:n (zoom out n times)
	# shl:n (shift left n bp)
	# shlp:n (shift left n% of current range)
	# shr:n (shift right n bp)
	# shrp:n (shift right n% of current range)
	# svgexport (export image in svg format)

	$bParams{offset} = 0
		if ( !exists( $bParams{offset} ) );

	if ( $newView =~ /^zoomin:(\d+\.\d+)/ )
	{
		my $factor = $1;
		$bParams{range} = int( ($bParams{range} / $factor) + 0.5 );
	} elsif ( $newView =~ /^zoomout:(\d+\.\d+)/ )
	{
		my $factor = $1;
		$bParams{range} = int( ($bParams{range} * $factor) + 0.5 );
	} elsif ( $newView =~ /^shl:(\d+)/ )
	{
		my $factor = $1;
		$bParams{offset} -= $factor;
	} elsif ( $newView =~ /^shlp:(\d+\.\d+)/ )
	{
		my $factor = $1;
		$bParams{offset} -= int($factor * $bParams{range});
	} elsif ( $newView =~ /^shr:(\d+)/ )
	{
		my $factor = $1;
		$bParams{offset} += $factor;
	} elsif ( $newView =~ /^shrp:(\d+\.\d+)/ )
	{
		my $factor = $1;
		$bParams{offset} += int($factor * $bParams{range});
	} elsif ( $newView =~ /^svgexport/ )
	{
		$bParams{svg} = 1;
	}

	return flatBrowserParams( \%bParams );
}

sub flatBrowserParams
{
	my $bParams = shift;
	my $flatParams = "";

	foreach my $key ( sort( keys( %{$bParams} ) ) )
	{
		if (($key ne 'data') && ($key !~ /^_/))
		{
			$flatParams .= "${key}=" . $bParams->{$key} . "&";
		}
	}
	$flatParams .= "data=";

	if ( $bParams->{mode} == 0 )
	{
		for (my $i = 0; $i < scalar( @{$bParams->{data}} ); $i++)
		{
			my $d = $bParams->{data}->[$i];
			$flatParams .= $d->{scaffoldId} . "," . $d->{posId};

			$flatParams .= ":"
				if ( $i < scalar( @{$bParams->{data}} ) - 1 );
		}
	} elsif ( $bParams->{mode} == 1 ) {
	    $flatParams .= join(",",@{ $bParams->{data} }); # list of locus Ids
	} elsif ( $bParams->{mode} == 2 ) {
		$flatParams .= join(",", @{$bParams->{data}});
	} elsif ( $bParams->{mode} == 3 ) {
		$flatParams .= join(",", @{$bParams->{data}->[0]->{orfs}}) . ":" .
				join(",", @{$bParams->{data}->[0]->{taxIds}});
	} elsif ($bParams->{mode} == 4) {
	    $flatParams .= join(":", @{$bParams->{data}});
	}

	return $flatParams;
}

sub parseCGIParameters
{
    my $query = new CGI;
    my $mode = $query->param('mode');
    my $range = rangeInt( $query->param('range') );
    my $data = $query->param('data');
    my $width = $query->param('width');
    my %bParams = ();
    
    $mode = $defaults->{mode}
    if ( !defined($mode) );
    
    $width = $defaults->{width}
    if ( !defined($width) || ($width < 1) );
    $width = $defaults->{minBrowserWidth}
    if ( $width < $defaults->{minBrowserWidth} );
    $bParams{width} = $width;
    
    if ( $mode == 0 )
    {
	# Parse data in anchored mode
	$range = rangeInt( $defaults->{range} )
	    if ( !defined($range) || (int($range) <= 0) );
	
	my @parseData = ();
	if ( defined($data) )
	{
	    foreach my $d ( split(/\s*:\s*/, $data) )
	    {
		if ( $d =~ /^(\d+)\s*,\s*(\d+)$/ )
		{
		    my %val = ();
		    $val{scaffoldId} = $1;
		    $val{posId} = $2;
		    push( @parseData, \%val );
		}
	    }
	}
	
	$bParams{mode} = 0;
	$bParams{range} = $range;
	$bParams{data} = \@parseData;
    } elsif ( $mode == 2 )
	{
	    # Parse data in anchored mode
	    $range = rangeInt( $defaults->{range} )
		if ( !defined($range) || (int($range) <= 0) );
	    
	    my @parseData = defined($data) ? split(/\s*,\s*/, $data) : ();
	    $bParams{mode} = 2;
	    $bParams{range} = $range;
	    $bParams{data} = \@parseData;
	} elsif ( $mode == 3 )
	{
	    my @parseData = ();
	    my $range = 0;
	    
	    # Parse data for dynamic set mode
	    if (defined($data))
	    {
		my ($orfData, $scaffoldData) = split(/\s*:\s*/, $data, 2);
		my @orfSet = split(/\s*,\s*/, $orfData);
		my @taxIdSet = split(/\s*,\s*/, $scaffoldData);
		my %data = ();
		$data{orfs} = \@orfSet;
		$data{taxIds} = \@taxIdSet;
		$range = ( scalar(@orfSet) * ($query->param('dynamicSetRange') ? $query->param('dynamicSetRange') : $defaults->{dynamicSetRange}) );
		$range += (scalar(@orfSet) - 1) * int( ($range / $width) * ($query->param('setSpacing') ? $query->param('setSpacing') : $defaults->{setSpacing}) );
		
		push( @parseData, \%data );
	    }
	    $bParams{mode} = 3;
	    $bParams{range} = $range;
	    $bParams{data} = \@parseData;
	} elsif ( $mode == 1 )
	{
	    # data is a list of locus Ids
	    # As of May 2008, this is not used by the site, but is provided
	    # for other sites to link into the genome browser to show a list of genes
	    my @parseData = split /,/, $data;
	    $bParams{data} = \@parseData;
	    $bParams{mode} = $mode;
	    $range = rangeInt( $defaults->{dynamicSetRange} )
		if ( !defined($range) || (int($range) <= 0) );
	    $bParams{range} = $range;
	    $bParams{offset} = 0;
	} elsif ($mode==4) {
	    $bParams{mode} = $mode;
	    my @data = split /:/, $data;
	    $bParams{data} = \@data;
	    $range = rangeInt( $defaults->{dynamicSetRange} )
		if ( !defined($range) || (int($range) <= 0) );
	    $bParams{range} = $range;
	    $bParams{offset} = 0;
	}

	#
	# Load rest of optional Browser parameters
	#
	my @keys = $query->param();
	foreach my $key ( @keys )
	{
		if ( ($key ne 'mode') && ($key ne 'range') && ($key ne 'data') && ($key ne 'width'))
		{
			$bParams{$key} = $query->param($key);
		}
	}

	return \%bParams;
}

1;
