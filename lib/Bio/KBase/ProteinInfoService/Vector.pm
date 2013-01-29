#!/usr/bin/env perl -w
package Bio::KBase::ProteinInfoService::Vector;
require Exporter;

use strict;

our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(min max sum sum2 sumProduct mean median var sd corr within
	     readDelim readDelimList readXLSAttrs readXLSList uniq readMatrix);

{
    sub min(@) {
	die if scalar @_ == 0;
	my $bestIndex = 0;
	foreach my $index (1..$#_) {
	    $bestIndex = $index if $_[$index] < $_[$bestIndex];
	}
	return $_[$bestIndex];
    }
    
    sub max(@) {
	die if scalar @_ == 0;
	my $bestIndex = 0;
	foreach my $index (1..$#_) {
	    $bestIndex = $index if $_[$index] > $_[$bestIndex];
	}
	return $_[$bestIndex];
    }
    
    sub sum( @ ) {
	my @x = @_;
	my $sum = 0;
	map { $sum += $_ } @x;
	return $sum;
    }
    
    sub sum2( @ ) {
	my @x = @_;
	my $sum2 = 0;
	map { $sum2 += $_ * $_ } @x;
	return $sum2;
    }
    
    sub mean( @ ) {
	my @x = @_;
	return 0 if scalar(@x) == 0;
	return sum(@x)/scalar(@x);
    }

    sub var {
	my @x = @_;
	return 0 if scalar (@x) < 2;
	my $meanX = mean(@x);
	return( (sum2(@x)-$meanX*$meanX*scalar(@x))/( (scalar(@x)-1) ) );
    }

    sub sd( @ ) {
	my @x = @_;
	my $varX = var(@x);
	return ($varX < 1e-8 ? 0 : sqrt($varX));
    }

    sub median( @ ) {
	my @sorted = sort { $a <=> $b } @_;
	return undef unless @sorted > 0;
	return (@sorted % 2 == 0 ? ($sorted[@sorted/2-1]+$sorted[@sorted/2])/2 : $sorted[(@sorted-1)/2]);
    }

    sub sumProduct( $$ ) {
        my ($listRef1,$listRef2) = @_;
	die "Lists of different lengths" if scalar @{$listRef1} != scalar @{$listRef2};
	# avoid slow indexing
	my %l1 = ();
        my $i = 0;
	foreach (@{$listRef1}) { $l1{$i++} = $_; }
	$i = 0;
        my $sumXY = 0;
	foreach (@{$listRef2}) { $sumXY += $_ * $l1{$i++}; }
	return($sumXY);
    }
        
   
    # accepts as input two references to lists
    sub corr( $$ ) {
        my ($listRef1,$listRef2) = @_;
	die "Lists of different lengths" if scalar @{$listRef1} != scalar @{$listRef2};
	my $n = scalar @$listRef1;
	die "Lists too short" if $n < 2;
	my $sum1 = sum( @$listRef1 );
	my $sum1sq = sum2( @$listRef1 );
	my $sum2 = sum( @$listRef2 );
	my $sum2sq = sum2( @$listRef2 );
	return ( (sumProduct($listRef1,$listRef2 ) - $sum1*$sum2/$n) /
		 sqrt(($sum1sq-$sum1*$sum1/$n)*($sum2sq-$sum2*$sum2/$n)) );
    }

    sub within(@) {
	my $test = shift;
	foreach (@_) { return 1 if $test eq $_; }
	return 0;
    }

    # given a tab-delimited file in R table format
    # (first row is the list of column names, then each row includes
    # the row name and the list of values), returns the matrix as a
    # hash of 'values', 'rows', and 'columns'
    # values is a list of lists (each list is a row)
    sub readMatrix($) {
	my ($file) = @_;
	open (READMAT, "<", $file) || die "Cannot read $file";
	$_ = <READMAT>;
	die "$file has no header line" if !($_);
	s/[\r\n]+$//;
	my @columns = split /\t/, $_;
	my @rows = ();
	my @values = ();

	while(<READMAT>) {
	    s/[\r\n]+$//;
	    my @F = split /\t/, $_;
	    die "Wrong number of columns in Bio::KBase::ProteinInfoService::Vector::readMatrix(\"$file\") -- compare header line\n"
		. join("\t",@columns)
		. "\n to \n".join("\t",@F)."\n..."
		if scalar(@F) != scalar(@columns)+1;
	    push @rows, (shift @F);
	    foreach (@F) { # test if numeric, strip padding
		s/^ +//;
		s/ +$//;
		# Note: ?= does lookahead (checks for the presence of the pattern without affecting downstream matching)
		die "Non-numeric value $_ in row $rows[-1] in Bio::KBase::ProteinInfoService::Vector::readMatrix(\"$file\")"
		    unless /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/
	    }
	    push @values, \@F;
	}
	return({'columns'=>\@columns, 'rows'=>\@rows, 'values'=>\@values});
    }

    # given a tab-delimited file with a header file, and a column name to index by,
    # return a hash of column name -> index -> value.
    sub readDelim($$) {
	my ($file, $indexCol) = @_;
	open (READDELIM, '<', $file) || die "Cannot read $file";
	$_ = <READDELIM>;
	die "$file has no header line" if !($_);
	s/[\r\n]+$//;
	my @header = split /\t/, $_, -1; # keep empty fields
	my %names = map { $_ => {} } @header;
	my %index = map { $header[$_] => $_ } (0..$#header);
	die "Cannot find index column $indexCol in $file" if !exists $index{$indexCol};
	my $iIndex = $index{$indexCol};
	
	while(my $line = <READDELIM>) {
	    $line =~ s/[\r\n]+$//;
	    my @columns = split /\t/, $line, -1; # keep empty fields
	    die "Wrong number of columns in $line from $file" if $#columns != $#header;
	    die "Dup index $columns[$iIndex]" if exists $names{$columns[$iIndex]};
	    foreach my $iCol (0..$#columns) {
		$names{$header[$iCol]}{$columns[$iIndex]} = $columns[$iCol];
	    }
	}
	close(READDELIM) || die "Cannot close $file";
	return \%names;
    }

    # given a tab-delimited file with a header file, return a list of column name -> value.
    # use instead of readDelim when you want to keep the order in the file
    sub readDelimList($) {
	my ($file) = @_;
	open (READDELIM, '<', $file) || die "Cannot read $file";
	$_ = <READDELIM>;
	die "$file has no header line" if !($_);
	s/[\r\n]+$//;
	my @header = split /\t/, $_, -1; # keep empty fields
	my @list = ();
	
	while(my $line = <READDELIM>) {
	    $line =~ s/[\r\n]+$//;
	    my @columns = split /\t/, $line, -1; # keep empty fields
	    die "Wrong number of columns in $line from $file" if $#columns != $#header;
	    my %names = ();
	    foreach my $iCol (0..$#columns) {
		$names{$header[$iCol]} = $columns[$iCol];
	    }
	    push(@list, \%names);
	}
	close(READDELIM) || die "Cannot close $file";
	return \@list;
    }

    # read just the attributes from a file with attributes of the form !Name=Value at the top
    sub readXLSAttrs($) {
	my ($file) = @_;
	my %attrs = ();

	open (READDELIM, '<', $file) || die "Cannot read $file";
	while(<READDELIM>) {
	    s/[\r\n]+$//;
	    if (m/^!/) {
	        if (m/^!([A-Za-z -+_.#\$ 0-9]+)=(.*)$/) {
		    die "Duplicate attr $1" if exists $attrs{$1};
		    $attrs{$1} = $2;
		} else {
		   die "No attr in line $_\n";
		}
	    } else {
		last;
	    }
	}
	close(READDELIM) || die "Cannot close $file";
	return (\%attrs);
    }
		      
    # read a tab-delimited file with optional attributes of the form !Name=Value before the header
    # returns a list of columnName->value and a hash of the attributes
    sub readXLSList($) {
	my ($file) = @_;
	my @header = ();
	my %attrs = ();

	open (READDELIM, '<', $file) || die "Cannot read $file";
	for(;;) {
	    $_ = <READDELIM>;
	    die "$file has no header line" if !($_);
	    s/[\r\n]+$//;
	    if (m/^!/) {
	        if (m/^!([A-Za-z -+_.#\$ 0-9]+)=(.*)$/) {
		    die "Duplicate attr $1" if exists $attrs{$1};
		    $attrs{$1} = $2;
		} else {
		   die "No attr in line $_\n";
		}
	    } else {
	    	@header = split /\t/, $_, -1; # keep empty fields
		last;
	    }
	}

	my @list = ();
	while(my $line = <READDELIM>) {
	    $line =~ s/[\r\n]+$//;
	    my @columns = split /\t/, $line, -1; # keep empty fields
	    die "Wrong number of columns in $line from $file" if $#columns != $#header;
	    my %names = ();
	    foreach my $iCol (0..$#columns) {
		$names{$header[$iCol]} = $columns[$iCol];
	    }
	    push(@list, \%names);
	}
	close(READDELIM) || die "Cannot close $file";
	return (\@list, \%attrs);
	
    }

    sub uniq(@) {
	return() if scalar @_ == 0;
	my @out = (shift);
	while (scalar @_ > 0) {
	      my $new = shift;
	      push @out, $new if $new ne $out[scalar(@out)-1];
	}
	return(@out);
    }
}

return 1;
