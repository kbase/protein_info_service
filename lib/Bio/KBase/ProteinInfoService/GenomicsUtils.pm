#!/usr/bin/env perl

# $Id: GenomicsUtils.pm,v 1.63 2012/05/10 03:55:08 kkeller Exp $

=head1 NAME

GenomicsUtils - low-level utilities for ESPP genomics db interaction

=head1 SYNOPSIS

    use Bio::KBase::ProteinInfoService::GenomicsUtils;
	# deprecated: use Bio::KBase::ProteinInfoService::Browser::DB::dbConnect() instead
    my $dbh=Bio::KBase::ProteinInfoService::GenomicsUtils::connect('dbhost');
    # do stuff

=head1 DESCRIPTION

GenomicsUtils does stuff.

=cut

package Bio::KBase::ProteinInfoService::GenomicsUtils;
require Exporter;

use strict;
use warnings;

use DBI;
use Time::HiRes;
use Carp;

# to avoid errors about SANDBOX_DIR being uninitialized
BEGIN {
	$ENV{SANDBOX_DIR}=$ENV{HOME} unless ($ENV{SANDBOX_DIR});
}

use lib
	"$ENV{SANDBOX_DIR}/Genomics/Perl/modules",
	"$ENV{SANDBOX_DIR}/Genomics/browser/lib";


#use Bio::KBase::ProteinInfoService::Gene;
use Bio::KBase::ProteinInfoService::Browser::DB;
use Bio::KBase::ProteinInfoService::Browser::Defaults;

BEGIN {
    our (@ISA, @EXPORT);
 
    @ISA = qw(Exporter);	
    @EXPORT = qw( connect disconnect dbh query queryList queryScalar queryTable queryHashList queryAttrs
	      getDebug setDebug warn
	      addToHashList );
}


    sub translation($);
    sub reverseComplement($);
    sub readFastaData($);
# Reads data from FASTA file
	
    sub readFASTA($);
# Read FASTA files from data directory

    sub dbh();
    sub getDebug;
    sub setDebug;
    sub query($@);
    
    sub queryList($@);
    sub queryScalar($@);
    sub queryAttrs($$$$$$);
    sub queryTable($$);
    sub queryHashList($);
    
    sub connect;
    sub disconnect();
    sub getSequence($;$;$;$);
# Returns gene's sequence.
# Parameters:
#    first - sequence
#    second - strand
#    		

sub formatFASTA($;$);
###//sub get_seq($;$;$);

sub setDebug;
sub getDebug;
sub warn;


my $DATA_DIR = "/data/genomics/data/genomes/";
my ( $noDebug, $warnings, $verbose, $full ) = ( 0, 1, 2, 10 );
my $debug_ = $warnings;

#--------------------------------------------------------
sub data_dir()
{
    return $DATA_DIR;
}

#--------------------------------------------------------

sub reverseComplement($) 
{
    my $seq = shift;
    chomp $seq;
	my $origSeq=$seq;

    die "Invalid sequence \"$origSeq\" in reverseComplement" if ( ($seq =~ 
tr/RYKMSWBDHVNATCGXrykmswbdhvnatcg-/YRMKWSVHDBNTAGCXyrmkwsvhdbntagc-/) != 
length($seq) );
    $seq = reverse $seq;
    return $seq;
}

#--------------------------------------------------------
sub readFastaData($)
{
    my $file = shift;
    open( F, "$file" ) or print STDERR "Cannot open file $file\n";
    my @lines = <F>;
    close F;
    my $dna = "";
    foreach my $l (@lines) {
	next if ( $l =~ /^>/ );
	chomp $l;  
	$dna .= $l;
    }

    return $dna;
}

sub readFASTA($)
{
    my $file = shift;
    $file = $DATA_DIR.$file;
    return readFastaData( $file );
}

#--------------------------------------------------------

sub dbh()
{
	# use these once officially deprecated
#	carp "This function is deprecated.  Please use Browser::DB::dbHandle instead";
	return Bio::KBase::ProteinInfoService::Browser::DB::dbHandle;
}

sub getDebug{
    return $debug_;
}

sub setDebug{
    $debug_ = 1;
    $debug_ = $_[0] if defined $_[0];
}

sub connect
{
	# use these once officially deprecated
#	carp "This function is deprecated.  Please use Browser::DB::dbConnect instead";
	my $host = $defaults->{dbHost};
	my $user_name = $defaults->{dbUser};
	my $password = $defaults->{dbPassword};
	my $dbname = $defaults->{dbDatabase};

	# try to emulate CGI's parameter-passing
	my (%params);
	%params=@_ if $_[0]&&($_[0] =~ /^-/);

	if (%params)
	{
		$host=$params{'-host'} || $host;
		$dbname=$params{'-dbname'} || $dbname;
		$user_name=$params{'-user'} || $user_name;
		$password=$params{'-pass'} || $password;
	} else
	{
	    $host = $_[0] if defined $_[0];
	}

    $host = "$host.qb3.berkeley.edu" unless $host eq "localhost" || $host =~ m/\./;

	Bio::KBase::ProteinInfoService::Browser::DB::dbConnect($host,$user_name,$password,$dbname);
	my $dbh = Bio::KBase::ProteinInfoService::Browser::DB::dbHandle;

    return $dbh;
}

sub disconnect(){
	# use these once officially deprecated.
#	carp "This function is deprecated.  Please use Browser::DB::dbDisconnect instead";
	Bio::KBase::ProteinInfoService::Browser::DB::dbDisconnect();
}


sub query($@){
    my $temp_dbh = Bio::KBase::ProteinInfoService::Browser::DB::dbHandle();
#    CORE::warn "temp_dbh is $temp_dbh";
    my $temp_statement = shift;
	my @temp_query_args = @_;

    die "No database handle yet" unless defined $temp_dbh;
    die "Undefined query" unless defined $temp_statement;
    my $start;
    if ($debug_>=10) {
	my $tmp2  = $temp_statement; $tmp2 =~ s/[\r\n\t]/ /g;
	my $dbname = $temp_dbh->{Name};
	print STDERR "GenomicsUtils (database $dbname): $tmp2\n";
	$start = [ Time::HiRes::gettimeofday( ) ];
    }
    #print qq{$temp_statement};
    my $sth = $temp_dbh->prepare (qq{$temp_statement});
    $sth->execute(@temp_query_args);

    my $refArray = $sth->fetchall_arrayref();
    $sth->finish(); 
    if ($debug_ >= 10) {
	my $elapsed = Time::HiRes::tv_interval( $start ); 
	$Bio::KBase::ProteinInfoService::GenomicsUtils::genomicsQueryCumulative += $elapsed;
	print STDERR "Query took $elapsed seconds (GenomicsUtils cumulative " . $Bio::KBase::ProteinInfoService::GenomicsUtils::genomicsQueryCumulative. ")\n";
    }
    &warn( "GenomicsUtils: query returned NULL result; $temp_statement" )
	unless $refArray->[0] || $debug_ <= 1;
    return $refArray;
}

sub queryList($@){
    return map {$_->[0]} @{&query(@_)};
}

sub queryScalar($@){
	my $query=shift;
    my $qRef = query($query,@_);
    return $qRef->[0][0];
}

# queryAttrs(table name, unique key name, unique key value, reference to list of attribute names,
#            hash to fill, suffix to put on names)
# returns: nothing
sub queryAttrs($$$$$$){
    my ($table, $keyName, $key, $refAttrs, $refHash, $suffix) = @_;
    my $result = &query("SELECT " . join(",", @$refAttrs) . " from $table where $keyName=$key");
    die "Missing or non-unique key $keyName=$key in $table" if scalar @$result != 1;
    $result = $result->[0];
    my @columns = @$refAttrs; # copy
    while(scalar @$result > 0) {
	$refHash->{(shift @columns) . $suffix} = shift @$result;
    }
}

# queryTable(attrNames, fromClause)
# returns reference to a list of hashes for each row, each of the form attr->value
sub queryTable($$) {
    my ($refAttrs, $from) = @_;
    my $result = &query("SELECT " . join(",", @$refAttrs) . " " . $from);
    my $list = [];
    foreach my $row (@$result) {
	my $hash = {};
	my @attrs = @$refAttrs;
	while (scalar @attrs > 0) {
	    $hash->{shift @attrs} = shift @$row;
	}
	push @$list, $hash;
    }
    return($list);
}

# queryHashList(query)
# returns a reference to a hash of key -> list of values
# query must return two-column results
sub queryHashList($) {
    my ($query) = @_;
    my $result = &query($query);
    my $hashRef = {};
    foreach my $row (@$result) {
	die "row size != 2: query $query" if scalar @$row != 2;
	addToHashList($hashRef, $row->[0], $row->[1]);
    }
    return($hashRef);
}

sub warn{
    return unless $debug_;
    my $warning = shift;
    my $level;
    $level = $warnings unless ($level = shift);
#    print STDERR "$warning\n" if $level >= $debug_;
    carp "$warning" if $level >= $debug_;
}

sub getSequence($;$;$;$) {
    my ($seq, $strand, $start, $end) = @_;
    my $sequence = substr(${$seq}, $start, $end - $start  + 1);

    if( $strand eq '-' ) {
	return reverseComplement( $sequence );
    }

    return $sequence;
}

#-------------------------------------------------------------------
sub formatFASTA($;$)
{
    my ($title, $sequence) = @_;
    return undef unless ($sequence);
    my $s = qq/>$title\n/;
    my @whole = $sequence =~ /.{1,60}/g;
    my $line = join "\n", @whole;
    return $s."$line\n";
}

sub addToHashList($$$) {
    my ($hashRef, $key, $value) = @_;
    if (!defined $hashRef->{$key}) {
	$hashRef->{$key} = [];
    }
    push @{ $hashRef->{$key} }, $value;
    return 1;
}

## stop codon is included in subroutine translation as * symbol
sub translation($){
    my $transcript = shift;
    if (length($transcript)%3){&warn("Transcript is not multiple of 3");}
    $transcript =~ tr/a-z/A-Z/;
    my %codonTable = (Bio::KBase::ProteinInfoService::Gene::codonUsageTable());
    my $protein = "";
    for(my $i = 0; $i < length($transcript); $i+=3){
	my $codon = substr($transcript, $i, 3);
	if ($codonTable{$codon}){
	    $protein .= $codonTable{$codon};
	}
	else{
	    $protein .= 'X';
	}

    } 
    
    return $protein;
    
}

my %AAMW = ('A' => 71.09,
	    'R' => 156.19,
	    'N' => 114.11,
	    'D' => 115.09,
	    'C' => 103.15,
	    'Q' => 128.14,
	    'E' => 129.12,
	    'G' => 57.05,
	    'H' => 137.14,
	    'I' => 113.16,
	    'L' => 113.16,
	    'K' => 128.17,
	    'M' => 131.19,
	    'F' => 147.18,
	    'P' => 97.12,
	    'S' => 87.08,
	    'T' => 101.11,
	    'W' => 186.21,
	    'Y' => 163.18,
	    'V' => 99.14);

# protein sequence to molecular weight
sub proteinMolecularWeight($) {
    my ($seq) = @_;
    my $MW = 0;
    for (my $i = 0; $i < length($seq); $i++) {
	$MW += ($AAMW{substr($seq,$i,1)} || 0);
    }
    return $MW;
}

# add shortName to a ref to a list of hashes that includes taxonomyId
sub AddTaxShortName($) {
    my ($list) = @_;
    return () if scalar(@$list) == 0;
    die "Called AddTaxShortName on objects without taxonomyId"
	unless scalar( grep {!exists $_->{taxonomyId}} @$list) == 0;
    my %tax = map {$_ => 1} map {$_->{taxonomyId}} @$list;
    my $taxSpec = join(",", keys %tax);
    my $shortNames = queryHashList(qq{SELECT taxonomyId,shortName FROM Taxonomy WHERE taxonomyId IN ($taxSpec)});
    foreach my $row (@$list) {
	my $tax = $row->{taxonomyId};
	$row->{shortName} = exists $shortNames->{$tax} ? $shortNames->{$tax}[0] : "Unknown taxonomyId $tax";
    }
}

#=======



sub proteinBlatSearch {

	# will want to move $shortSeqAA to Browser::Defaults
my ($fastaFile,$fastaUri,$debug,$seq,$shortSeqAA,$noOutput)=@_;
	my $blatFile = "$fastaFile.psl";
	my $blatUri = "$fastaUri.psl";
	if (! -e $blatFile) {
	    print qq{<p>Searching for near-exact matches first...</p>\n}
	    	unless $noOutput;
	    foreach my $gfPort (@{$defaults->{transBlatPort}})
	    {
	        my $blatCmd = join(" ",
			       $defaults->{GFCLIENT},
			       $defaults->{transBlatServer},
			       $gfPort,
			       "-maxIntron=2000",
			       "-minScore=30",
			       "-minIdentity=80",
			       "-out=blast8",
			       "-q=prot",
			       "-t=dnax",
			       $defaults->{transBlatPath},
			       $fastaFile,
			       "$blatFile.$$")
		. " >& /dev/null ; mv $blatFile.$$ $blatFile.$$.port$gfPort";
	    print STDERR "Running $blatCmd\n" if $debug;
	    system("$blatCmd >& /dev/null") == 0 || die "Error running $blatCmd";
	    $? == 0 || die "Error running $blatCmd";
	    }
		# restore blat sort by score descending
		system("sort -nr -k12 $blatFile.$$.port* > $blatFile.$$.final && mv $blatFile.$$.final $blatFile && rm $blatFile.$$.port*");
	} else {
	    print STDERR "Using cached $blatFile\n" if $debug;
	}
	
	my @blathits = ();
	open(BLAT,"<",$blatFile) || die "Cannot read $blatFile";
	while(<BLAT>) {
	    chomp;
	    my @F = split /\t/, $_;
	    die "Error parsing $blatFile" unless @F >= 12;
	    # eliminate weak hits, and don't try to be complete (supposed to be fast)
#	    push @blathits, \@F if ($F[10] < 0.02);
	    push @blathits, \@F if ($F[10] < 0.02 or length($seq) < $shortSeqAA);
	    last if @blathits >= 100;
	}
	close(BLAT) || die "Error reading $blatFile";
	
	# Convert nt hits to gene hits
	# Only do this when gene contains most of the hit
	my $blastFile2 = "$blatFile.blastp";
	my $blastUri2 = "$blatUri.blastp";
	
	my @blatcomb = (); # combined blat and blastp hits
	if (@blathits == 0) {
	    print STDERR "No blat hits, skipping search for protein hits\n" if $debug;
	} elsif (! -e $blastFile2) {
	    # First, find the candidate genes
	    print STDERR "Finding candidate genes for blat search\n" if $debug;
	    my @rules = ();
	    foreach my $hit (@blathits) {
		my ($crc2,$scaffoldId,$identity,$length,$mm,$gap,$qBeg,$qEnd,$scBeg,$scEnd,$eval,$score) = @$hit;
		my ($begin,$end) = sort {$a <=> $b} ($scBeg,$scEnd);
		my $kbt1 = int($begin/10000);
		my $kbt2 = int($end/10000);
		foreach my $kbt ($kbt1..$kbt2) {
		    push @rules, "(s.scaffoldId=$scaffoldId AND s.kbt=$kbt)";
		}
	    }

	    # we are joining AASeq here to make sure we get only proteins
	    # with actual sequences (else it won't be in proteomes.faa, 
	    # and fastacmd will die with an error)
	    my @loci = queryList("SELECT l.locusId FROM ScaffoldPosChunks s JOIN Locus l"
				 . " USING (locusId,version)"
				 . ' JOIN AASeq ls USING (locusId,version)'
				 . " WHERE l.priority=1 AND l.type=1"
				 . " AND (" . join(" OR ", @rules) . ")");
	    if (@loci > 0) {
		# Find BLAST hits
	    	print STDERR "Finding BLAST hits from blat search candidates\n" if $debug;
		my $tmpdb = $blastFile2."tmpdb.$$";
		my $blastdb = "$ENV{SANDBOX_DIR}/Genomics/cgi/blast/db/proteomes.faa";
		my $listfile = "$tmpdb.list";
		
		open(LIST,">",$listfile) || die "Cannot write to $listfile";
		foreach (@loci) { print LIST "VIMSS$_\n"; }
		close(LIST) || die "Error writing to $listfile";
		
		my $fastacmd = "$defaults->{FASTACMD} -d $blastdb -p T -i $listfile > $tmpdb";
		print STDERR "Running $fastacmd\n" if $debug;
		(system($fastacmd) == 0 && -e $tmpdb && ! -z $tmpdb) || die "Cannot run $fastacmd: $!";
		
		my $formatcmd = "$defaults->{FORMATDB} -i $tmpdb -p T";
		print STDERR "Running $formatcmd\n" if $debug;
		system($formatcmd);
		
		# no more -z, not convinced it's needed for this purpose
		my $blastcmd = "$defaults->{BLASTALL} -p blastp -i $fastaFile -d $tmpdb -e 0.01 -m 8"
		    . " -v 100000 -b 100000 -F F -o $tmpdb.blast";
		if (length $seq < $shortSeqAA)
		{
			print STDERR "Short query sequence; setting high e-value\n" if $debug;
			$blastcmd = "$defaults->{BLASTALL} -p blastp -i $fastaFile -d $tmpdb -m 8"
			    . " -v 100000 -b 100000 -F F -o $tmpdb.blast -e 1000";
		}

		print STDERR "Running $blastcmd\n" if $debug;
		(system($blastcmd) == 0 && -e "$tmpdb.blast") || die "Cannot run $blastcmd";

		# save the output
		(system("mv $tmpdb.blast $blastFile2") == 0 && -e $blastFile2) || die "Cannot create $blastFile2";
		
		unless ($debug)
		{
			unlink($listfile);
			unlink($tmpdb);
			foreach my $suffix (qw(phr pin psd psi psq)) {
			    unlink("$tmpdb.$suffix");
			}
			unlink("$tmpdb.blast");
		}
    	} else {
		# make empty hits file
		print STDERR "Blat hits but no corresponding proteins to search for blast hits\n" if $debug;
		open(BBLASTHITS,">",$blastFile2) || die "Cannot write $blastFile2";
		close(BBLASTHITS);
	    }
	} else {
	    print STDERR "Using cached blast-hits2 (blastp from blat hits) file $blastFile2\n" if $debug;
	}
	
	my @bblasthits = ();
	if (@blathits > 0) {
	    open(BBLAST,"<","$blastFile2") || die "Cannot read $blastFile2";
	    while(<BBLAST>) {
			chomp;
			my @F = split /\t/, $_;
			# skip proteins with a poor identity
#			next unless ($F[2] > 80);
			$F[1] =~ s/^lcl[|]VIMSS//;
			push @bblasthits, \@F;
	    }
	    close(BBLAST) || die "Error reading $blastFile2";
	}

	return (\@blathits,\@bblasthits,$blatUri,$blastUri2);

}


sub crc64($) {
    my ($str) = @_;
    my $POLY64REVh = 0xd8000000;
    my @CRCTableh;
    my @CRCTablel;

    @CRCTableh = 256;
    @CRCTablel = 256;
    for (my $i=0; $i<256; $i++) {
	my $partl = $i;
	my $parth = 0;
	for (my $j=0; $j<8; $j++) {
	    my $rflag = $partl & 1;
	    $partl >>= 1;
	    $partl |= (1 << 31) if $parth & 1;
	    $parth >>= 1;
	    $parth ^= $POLY64REVh if $rflag;
	}
	$CRCTableh[$i] = $parth;
	$CRCTablel[$i] = $partl;
    }

    my $crcl = 0;
    my $crch = 0;

    foreach (split '', $str) {
	my $shr = ($crch & 0xFF) << 24;
	my $temp1h = $crch >> 8;
	my $temp1l = ($crcl >> 8) | $shr;
	my $tableindex = ($crcl ^ (unpack "C", $_)) & 0xFF;
	$crch = $temp1h ^ $CRCTableh[$tableindex];
	$crcl = $temp1l ^ $CRCTablel[$tableindex];
    }
    my $crc64 = sprintf("%08X%08X", $crch, $crcl);

    return $crc64;

}

#END 


return 1;

=head1 AUTHORS

Eric Alm, Katherine Huang, Dylan Chivian, Wayne Huang, Marcin
Joachimiak, Keith Keller, Morgan Price, Paramvir Dehal, Adam Arkin

=cut

