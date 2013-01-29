#!/usr/bin/perl
package Genome;
require Exporter;

# $Id: Genome.pm,v 1.52 2012/06/13 18:38:26 jkbaumohl Exp $

=head1 NAME

Genome - interface to Genome object from ESPP genomics database

=head1 SYNOPSIS

    use Genome;
    my $genome=Bio::KBase::ProteinInfoService::Genome::new(taxonomyId=>$taxId);
    my $name=$genome->name;
    my @genes=$genome->genes;
    # do stuff

=head1 DESCRIPTION

Genome does stuff.

=cut

use strict;

use DBI;
use IO::String;
use Bio::SeqIO;
use Digest::MD5 qw (md5_hex);

use Bio::KBase::ProteinInfoService::GenomicsUtils;
use Bio::KBase::ProteinInfoService::Scaffold;
use Bio::KBase::ProteinInfoService::Gene;
# for uarray support? good idea?
use Bio::KBase::ProteinInfoService::ACL;

our (@ISA, @EXPORT);
 
@ISA = qw(Exporter);	
@EXPORT = qw( getGenomeMap getGenomeList lineage getChildTaxa doesExpHaveLogLevelData doesTaxHaveLogLevelData);

{

sub new;
# Constructor for gene object. Returns Genome object.
# Currently only takes (requires) "taxonomyId => xxx" as input.

#--------------------------------------------------------------
#The following functions return basic info about genomes and are
#relatively self-explanatory.

sub name;
sub shortName;
sub placement;
sub choppedName;
sub taxonomyId;
sub lineage;
sub ncbiProjectId;

# boolean convenience method, to determine if a genome has only
# plasmids or has real genomic sequence data
sub hasGenomicScaffolds;

# Returns a list of scaffold objects.  Only genomic (not plasmid)
# scaffolds are returned.
sub scaffolds;
# Returns a list of nongenomics scaffold objects.
sub nongenomicScaffolds;


sub genes; # Returns a list of genes objects on genomic scaffolds
sub nongenomicGenes; # Returns a list of genes objects on non-genomic scaffolds
sub basicInfo; #a genome may be incomplete, a chromosome could have multiple scaffolds.  basicInfo is a convenient way to pull out basic info summarizing all scaffolds.  This method returns a hash table.

sub genbank; # Returns Genbank-format output of the entire genome
sub tabExport; # Returns tab-delimited output of genes
sub fastaGeneExport; # Returns a FASTA-format file of genes
sub fastaScaffoldExport; # Returns a FASTA-format file of genes

sub scaffoldMD5sums; # returns a hashref of all the MD5 sums of the contigs
sub md5sum; # returns an MD5 of the concatenated MD5s of the contigs

# returns a list of microarray experiment IDs for this genome
# optionally filtered by userId
# (note returns integers, not any sort of object)
sub expIds;


#--------------------------------------------------------------

sub getGenomeMap;
sub getGenomeList;

# These functions return a set of genome objects corresponding to all
# the genomes in the DB, wither as a list or as a hash keyed on
# taxonomyId.

sub getChildTaxa;
sub getPath;
sub pmid; #return the PubMed ID
sub publication; #return the genome paper info

#--------------------------------------------------------------

=head1 CONSTRUCTOR

=over 4

=item Genome::new (taxonomyId=>TAXID);

This is a subroutine (not a method) to create a new Genome object.
C<taxonomyId> is the NCBI taxonomyId (or, in some cases, the internal
ESPP taxonomyId) of the organism, and is a required parameter.

=back

=cut

sub new{
    my %params = @_;
    my $taxonomyId = $params{'taxonomyId'};
    my $self = {};
    bless $self;
    
    unless ($params{'skipScaffolds'})
    {
    	my @scaffoldIds = Bio::KBase::ProteinInfoService::GenomicsUtils::queryList( qq{ SELECT scaffoldId FROM Scaffold WHERE taxonomyId=$taxonomyId AND isActive=1 } );

    	my @scaffolds;
    	foreach my $sId (@scaffoldIds){
			push @scaffolds, Bio::KBase::ProteinInfoService::Scaffold::new(
				scaffoldId => $sId , cacheScaffolds=>$params{'cacheScaffolds'}
				);
	    }

	    $self->{scaffolds_} = \@scaffolds;
    }

    $self->{taxonomyId_} = $taxonomyId;
    if (defined $params{'name'}){
	$self->{name_} = $params{'name'};
	$self->{shortName_} = $params{'shortName'};
	$self->{placement_} = $params{'placement'};
    }else {
		my $queryResult=Bio::KBase::ProteinInfoService::GenomicsUtils::query( "SELECT name, shortName, placement FROM Taxonomy WHERE taxonomyId=$taxonomyId" );
		return undef unless $queryResult->[0];
		($self->{name_}, $self->{shortName_}, $self->{placement_}) =
	    @{$queryResult->[0]};
		# query( "SELECT name, shortName, placement FROM Taxonomy WHERE taxonomyId=$taxonomyId" )->[0] };
    }
    return $self;
}

=head1 METHODS

=over 4

=item name

Returns the full name of the organism (usually from NCBI Taxonomy).

=cut

sub name{
    my $self = shift;
    return $self->{name_};
}

=item shortName

Returns the short name of the organism.

=cut

sub shortName{
    my $self = shift;
    return $self->{shortName_};
}

=item choppedName

Returns an abbreviated name of the organism, generally the first
three characters of the genus and species, followed by the first
five characters of the strain.

=cut

sub choppedName{
    my $self = shift;
    my $name = $self->{shortName_};
    my @temp = split /\s/, $name;
    $temp[0] =~ s/(\w\w\w).*/$1/;
    $temp[1] =~ s/(\w\w\w).*/$1/ if $temp[1];
    $temp[2] =~ s/(\w\w\w\w\w).*/$1/ if $temp[2];
    $name = $temp[0].".";
    $name .= " $temp[1]" if $temp[1];
    $name .= " ".$temp[2] if $temp[2];
    return($name);
}

=item placement

Returns the placement field from the database (obsolete).

=cut

sub placement{
    my $self = shift;
    return $self->{placement_};
}

=item taxonomyId

Returns the taxonomyId of the organism (usually from NCBI Taxonomy).

=cut


sub taxonomyId{
    my $self = shift;
    return $self->{taxonomyId_};
}
#my %lineage = ();


=item getPath

Returns a marked-up classification (with HTML links to NCBI).

=cut

sub getPath{
    my $self = shift;
    my $tId = $self->taxonomyId();
    my $pathR = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{SELECT TaxName.taxonomyId, name FROM TaxParentChild, TaxName WHERE childId=$tId AND TaxName.taxonomyId=parentId and TaxName.class="scientific name" and parentId not in (1, 131567) order by TaxParentChild.nDistance desc});
    my @path;
    foreach my $row (@$pathR){
	if ($row->[0] > 0 && $row->[0] < 1000000000000) {
	    push @path, qq{<A HREF="http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=$row->[0]">$row->[1]</A>};
	} else {
	    push @path, qq{$row->[1]};
	}
    }
    return @path;

}

=item scaffolds

Returns a list of genomic Scaffold objects (i.e., no scaffolds that
are on plasmids).

=cut

sub scaffolds{
    my $self = shift;
    return grep {$_->isGenomic()} @{$self->{scaffolds_}};
}

sub hasGenomicScaffolds {
	my $self=shift;
	# actually returns a count of genomic scaffolds
	return scalar $self->scaffolds if ref $self;
	# could make this polymorphic, to run as a vanilla sub as well as an
	# object method; it's a lot faster without creating the genome object
	my $taxonomyId=$self; # $self is not an object
	my $query="SELECT count(*) FROM Scaffold WHERE isActive=1 AND isGenomic=1 AND taxonomyId=$taxonomyId";
	my $count=Bio::KBase::ProteinInfoService::GenomicsUtils::queryScalar($query);
	return $count;
}

sub nongenomicScaffolds{
    my $self = shift;
    return grep {! $_->isGenomic()} @{$self->{scaffolds_}};
}

=item basicInfo

Returns a hash reference of information about the genome. Given a
hashref $basicInfo:

    $basicInfo=$genome->basicInfo;
	
%$basicInfo has two keys, genomic and plasmid. The
values of $basicInfo->{genomic} and
$basicInfo->{plasmid} are also hash references of the
chromosome number; finally, within these values are hash
references too (need to finish).

=cut

sub basicInfo{
    my $self = shift;
	# if this exists, we want to only report on these scaffolds
	# (to handle ACLs)
	my @scaffoldIds=@_;
    my $taxonomyId=$self->{taxonomyId_};
	my $scaffoldIdSql=undef;
	if (@scaffoldIds)
	{
		$scaffoldIdSql='AND s.scaffoldId IN ('
			. (join ',',@scaffoldIds)
			. ')';
	}
    my $sql = qq{
	SELECT lc.nGenes,s.isCircular, s.chr_num, s.length, s.file, s.isGenomic, s.isPartial, s.gi,ss.sequence
	    FROM ScaffoldSeq ss NATURAL JOIN Scaffold s LEFT JOIN LocusCount lc USING (scaffoldId,taxonomyId)
	    WHERE s.isActive=1
	    AND s.taxonomyId=$taxonomyId
		$scaffoldIdSql
	    GROUP BY s.scaffoldId
	    ORDER BY s.isGenomic DESC
    };
    my $infoR = Bio::KBase::ProteinInfoService::GenomicsUtils::query($sql);
    my %info = ();
    my $flag = 'genomic';
    my $count = 0;
    my $previousChr = -1;
    foreach (@$infoR){
		my ($geneCount, $isCir, $chr, $length, $source, $isGenomic, $isPartial, $gi,$scaffoldSeq)= @$_;
		$chr = "chromosome No ".$chr;
		if ($previousChr ne $chr and $previousChr>-1)
		{
			++$count;
#			$info{$flag}{$previousChr}{'GC content'}=$info{$flag}{$previousChr}{'GC content'}/$info{$flag}{$previousChr}{'genome size'};
			$info{$flag}{$previousChr}{'GC content'}=
				sprintf("%.2f",$info{$flag}{$previousChr}{'GC content'}/$info{$flag}{$previousChr}{'genome size'}*100).'%'
					if ($info{$flag}{$previousChr}{'genome size'});
		}
		
		if ($isGenomic==0){$flag = 'plasmid'}

		# why is this here?
		$source = "TIGR" if $source =~ /NC_900002/;

		$info{$flag}{$chr}{"scaffold count"}++; #scaffold count of the same chromosome
		$info{$flag}{$chr}{"genome size"} += $length;
		$info{$flag}{$chr}{"locus count"} += $geneCount;
		if ($info{$flag}{$chr}{"scaffold count"} == 1){ #when scaffold count == 1      
		    $info{$flag}{$chr}{type} = $isCir?"circular":"linear";
		    $info{$flag}{$chr}{source} = $source;
			for ($source)
			{
				/^NC_/ and $info{$flag}{$chr}{source} = "<a href=\"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=Genome&cmd=search&term=$source\"><span class=body12u>$source</span></a>";
				/^N[ZW]_/ and $info{$flag}{$chr}{source} = "<a href=\"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=Nucleotide&cmd=search&term=$source\"><span class=body12u>$source</span></a>";
			}
#		    $info{$flag}{$chr}{source} = ($source =~ /ORNL|JGI|TIGR/) ? $source : "<a href=\"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=Genome&cmd=search&term=$source\"><span class=body12u>$source</span></a>";
		    $info{$flag}{$chr}{status} = $isPartial?"incomplete":"complete";
		}
	    (my $gc = $scaffoldSeq) =~ s/[ATat]//g;
		$gc=length($gc);
#	    $gc = sprintf("%.2f",length($gc)/length($scaffoldSeq)*100)
#	    	if ($scaffoldSeq);
#	    $gc='unknown' unless $gc;
#	    $gc .= "%";
		$info{$flag}{$chr}{'GC content'}+=$gc;
		$previousChr = $chr;
	}

	# handle the last chromosome
	$info{$flag}{$previousChr}{'GC content'}=
		sprintf("%.2f",$info{$flag}{$previousChr}{'GC content'}/$info{$flag}{$previousChr}{'genome size'}*100).'%'
			if ($info{$flag}{$previousChr}{'genome size'});

    return \%info;
}

# Passes along arguments, ultimately reaching Bio::KBase::ProteinInfoService::Scaffold::fetchGenesListRef
sub genes{
    my $self = shift;
    return map {$_->genes(@_)} $self->scaffolds();
}

# proteins on the genomic sequences
sub proteins{
    my $self = shift;
    if (!defined($self->{genes_})){$self->genes()};
    print "hello";
    map{print $_->type;} @{$self->{genes_}};
    return;
}

## Retrieve plasmid genes
sub nongenomicGenes{
    my $self = shift;
    return map {$_->genes(@_)} $self->nongenomicScaffolds();
}

# returns hash of name (from synonyms or as locus id) -> list of locusIds
sub getOrfIdsByName($@) {
    my $self = shift;
    my @names = @_;
    my $hash = Bio::KBase::ProteinInfoService::GenomicsUtils::queryHashList( "SELECT DISTINCT s.name,s.locusId from Synonym s,Locus o,Position p,Scaffold sc"
			       . " WHERE sc.taxonomyId=" . $self->taxonomyId()
			       . " AND s.locusId=o.locusId and o.posId=p.posId AND p.scaffoldId=sc.scaffoldId"
			       . " AND s.name IN (" . join(",",map("'$_'",@names)) . ")" );
    my @numeric = grep m/^[0-9]+/, @names;
    if (scalar @numeric > 0) {
	map { addToHashList($hash, $_, $_) } Bio::KBase::ProteinInfoService::GenomicsUtils::queryList("SELECT o.locusId FROM Locus o,Position p,Scaffold sc"
							. " WHERE sc.taxonomyId=" . $self->taxonomyId()
							. " AND o.locusId IN (" . join(",",@numeric) . ")"
							. " AND o.posId=p.posId AND p.scaffoldId=sc.scaffoldId");
    }
    return($hash);
}

sub getGenomeMap{
    return map {$_->taxonomyId(),$_} getGenomeList(@_);
}

sub getGenomeList{
    my %params = @_;
    return map { Genome::new('taxonomyId' => $_,$params{'skipScaffold'}) } Bio::KBase::ProteinInfoService::GenomicsUtils::queryList("SELECT DISTINCT t.taxonomyId FROM Taxonomy t JOIN Scaffold s USING (taxonomyId) WHERE s.isActive=1");
}

# list of taxonomyIds to list of child taxonomyIds
# only those loaded in the database
sub getChildTaxa{
    return () if scalar @_ == 0;
    return Bio::KBase::ProteinInfoService::GenomicsUtils::queryList("SELECT DISTINCT childId FROM TaxParentChild, Taxonomy, Scaffold"
				    . " WHERE parentId IN (" . join(",", @_) . ")"
				    . " AND Taxonomy.taxonomyId=childId"
				    . " AND Taxonomy.taxonomyId=Scaffold.taxonomyId AND Scaffold.isActive=1"
				    . " ORDER BY Taxonomy.placement");
}

sub pmid{
    my $self = shift;
    my $taxId = $self->taxonomyId();
    my $queryR = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{SELECT PMID FROM Taxonomy where taxonomyId=$taxId});
    return undef unless $queryR->[0][0];
    return $queryR->[0][0];

}

sub ncbiProjectId{
    my $self = shift;
    my $taxId = $self->taxonomyId();
    my $queryR = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{SELECT ncbiProjectId FROM Taxonomy where taxonomyId=$taxId});
    return undef unless $queryR->[0][0];
    return $queryR->[0][0];

}

sub publication{
    my $self = shift;
    my $taxId = $self->taxonomyId();
    my $queryR = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{SELECT Publication FROM Taxonomy where taxonomyId=$taxId});
    return undef unless $queryR->[0][0];
    return $queryR->[0][0];

}

## lineage is not a method of a genome object, this is just a subroutine, example syntax: @ranks = Genome::lineage(taxonomyId=>882);
sub lineage{
    my %info = @_;
    my $taxId = $info{taxonomyId};
    my $parentR = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{SELECT T.rank, t.name, T.parentId FROM TaxNode T, TaxName t WHERE t.taxonomyId=T\
					      .taxonomyId AND t.class="Scientific name" AND T.taxonomyId=$taxId});
    my ($rank, $name, $parentId) = @{$parentR->[0]};
    #$lineage{$parentRank} = $parentName;                                                                                  
    $rank = "genome" if $rank eq "no rank";
    my @lineage = ($rank.": ".$name);

    unshift @lineage, &lineage(taxonomyId=>$parentId) unless $parentId==131567;  #taxonomy ID 131567: cellular organisms   
    return @lineage;
}


sub genbank {

my $self=shift;

my $output;
my $io=IO::String->new(\$output);
my $seqio=Bio::SeqIO->new(-fh=>$io,-format=>'genbank');

foreach my $scaffold ($self->scaffolds,$self->nongenomicScaffolds)
{
	my $scaffoldseq=$scaffold->sequence;
	$scaffoldseq=~s/[^atgcATGC]//g;

	my $description=$self->name. ' ' . $scaffold->comment . ' VIMSS scaffoldId '. $scaffold->scaffoldId;
	my $genomeName=$self->name;
	# very crude way to not duplicate genome names
	# but keep other scaffold comments in the description
	$description=$scaffold->comment . ' VIMSS scaffoldId '. $scaffold->scaffoldId
		if ($scaffold->comment=~/^$genomeName/);

	my $seqobj=Bio::Seq->new(
		-seq=>$scaffoldseq,
		-display_id=>$scaffold->scaffoldId,
		-desc=>$description,
		-accession_number=>$scaffold->file,
		-is_circular=>$scaffold->isCircular,
	);
	
	my $genomeFeat=Bio::SeqFeature::Generic->new(
		-primary_tag=>'source',
		-start=>1,
		-end=>$scaffold->length,
		-tag=> {
			db_xref=>'taxon:'.$self->taxonomyId,
			organism=>$self->name,
			},
		);
	$seqobj->add_SeqFeature($genomeFeat);

	foreach my $gene ($scaffold->genes)
	{
		my $strand=1;
		$strand=-1 if ($gene->strand eq '-');

		my $feat=Bio::SeqFeature::Generic->new(
			-primary_tag=>'gene',
			-tag=> {
				db_xref=> 'VIMSS'.$gene->locusId,
				},
			-start=>$gene->begin,
			-end=>$gene->end,
			-strand=>$strand,
			);
		$feat->add_tag_value('gene',$gene->synonym->{0}) if ($gene->synonym->{0});
		$feat->add_tag_value('locus_tag',$gene->synonym->{1}) if ($gene->synonym->{1});
		$feat->add_tag_value('db_xref','GeneID:'.$gene->synonym->{5}) if ($gene->synonym->{5});
		$feat->add_tag_value('pseudo','y') if ($gene->isPseudo);
		$feat->add_tag_value('comment','CRISPR') if ($gene->type == 9);
		$feat->add_tag_value('comment','CRISPR spacer') if ($gene->type == 10);

		$seqobj->add_SeqFeature($feat);			

		if ($gene->isProtein)
		{
			my $cdsFeat=Bio::SeqFeature::Generic->new(
				-primary_tag=>'CDS',
				-tag=> {
					db_xref=> 'VIMSS'.$gene->locusId,
					product=>$gene->description,
					translation=>$gene->protein,
					},
				-start=>$gene->begin,
				-end=>$gene->end,
				-strand=>$strand,
				);
			$cdsFeat->add_tag_value('locus_tag',$gene->synonym->{1}) if ($gene->synonym->{1});
			$cdsFeat->add_tag_value('gene',$gene->synonym->{0}) if ($gene->synonym->{0});
			$cdsFeat->add_tag_value('protein_id',$gene->synonym->{3}) if ($gene->synonym->{3});
			$cdsFeat->add_tag_value('db_xref','GI:'.$gene->synonym->{2}) if ($gene->synonym->{2});
			$cdsFeat->add_tag_value('db_xref','GeneID:'.$gene->synonym->{5}) if ($gene->synonym->{5});
			$cdsFeat->add_tag_value('db_xref','SEED:'.$gene->seedId) if ($gene->seedId);
			$cdsFeat->add_tag_value('EC_number',$gene->ecNum) if ($gene->ecNum);
			$seqobj->add_SeqFeature($cdsFeat);
		}

		if ($gene->istRNA or $gene->isrRNA)
		{
			my $primary='rRNA';
			$primary='tRNA' if ($gene->istRNA);
			my $rnaFeat=Bio::SeqFeature::Generic->new(
				-primary_tag=>$primary,
				-tag=> {
					db_xref=> 'VIMSS'.$gene->locusId,
					product=>$gene->description,
					},
				-start=>$gene->begin,
				-end=>$gene->end,
				-strand=>$strand,
				);
			$rnaFeat->add_tag_value('locus_tag',$gene->synonym->{1}) if ($gene->synonym->{1});
			$rnaFeat->add_tag_value('gene',$gene->synonym->{0}) if ($gene->synonym->{0});
			$rnaFeat->add_tag_value('db_xref','GeneID:'.$gene->synonym->{5}) if ($gene->synonym->{5});
			$seqobj->add_SeqFeature($rnaFeat);	
		}

	}

	$seqio->write_seq($seqobj);

}

# crude hack to handle the pseudo tag
# bioperl isn't letting me add the tag without a value
$output=~s/\/pseudo="y"/\/pseudo/g;

return $output;
	
}


sub tabExport {

my $self=shift;

# would be nice to be able to specify these fields on the fly
my $out=join "\t",qw(locusId	accession	GI	scaffoldId start	stop	strand	sysName	name	desc	COG	COGFun	COGDesc TIGRFam	TIGRRoles GO	EC	ECDesc);
$out.="\n";

my $species=$self->name;
my $locusTypes=Bio::KBase::ProteinInfoService::GenomicsUtils::queryHashList('SELECT type,description FROM LocusType');

foreach my $scaffold ($self->scaffolds, $self->nongenomicScaffolds)
{
	foreach my $gene ($scaffold->genes)
	{
		my $locusId = $gene->locusId;
		my $gi = $gene->synonym()->{2};
		my $acc =  $gene->synonym()->{3};
		my $description = $gene->description;
		my $geneName = ($gene->synonym()->{0} or $gene->synonym()->{1} or $gene->synonym()->{6} or $locusTypes->{$gene->type}[0]);
		my $sysName = $gene->synonym()->{1};
		my $go = join ',', map { (split / /)[1] } @{ $gene->go() };
		my $ec = join ',', map { (split /\t/)[0] } @{ $gene->ec() };
		my $ecDesc = join ',', map { (split /\t/)[1] } @{ $gene->ec() };
		my $tigrfam = join ',',@{$gene->tigr};
		my $tigrfun = $gene->tigrFunCat;

		$out.=join "\t",
			$locusId,$acc,$gi,$gene->scaffoldId,
			$gene->start,$gene->stop,$gene->strand,
			$sysName,$geneName,$description,
			($gene->cog ? 'COG'.$gene->cog : ''),$gene->cogFunCode,$gene->cogDesc,
			$tigrfam,$tigrfun,
			$go,$ec,$ecDesc;
		$out.="\n";
	}
}

return $out;

}


sub fastaGeneExport {

my $self=shift;
# this is a hashref
my $params=shift;
my $exportType=$params->{exportType};

my $locusTypes=Bio::KBase::ProteinInfoService::GenomicsUtils::queryHashList('SELECT type,description FROM LocusType');

my $out;

my $species=$self->name;
foreach my $scaffold ($self->scaffolds, $self->nongenomicScaffolds)
{
	foreach my $gene ($scaffold->genes)
	{
		next if ($exportType eq 'proteomes' and !($gene->isProtein));
		my $locusId = $gene->locusId;
		my $geneName = ($gene->synonym()->{0} or $gene->synonym()->{1} or $gene->synonym()->{6} or $locusTypes->{$gene->type}[0]);
		my $description = ($gene->description) ? $gene->description : '';
		my $fastaHeader = "VIMSS$locusId $geneName $description [$species]";
		my $sequence;
		$sequence = $gene->dna if ($exportType eq 'transcriptomes');
		$sequence = $gene->protein if ($exportType eq 'proteomes');
		$out.=Bio::KBase::ProteinInfoService::GenomicsUtils::formatFASTA($fastaHeader,$sequence);
	}
}

return $out;

}

sub fastaScaffoldExport {

my $self=shift;

}


sub scaffoldMD5sums {

my $self=shift;

my %md5sums = map {$_->md5sum,$_} $self->scaffolds,$self->nongenomicScaffolds;

return \%md5sums;

}


sub md5sum {

my $self=shift;

return md5_hex(join '',sort keys %{$self->scaffoldMD5sums});

}


sub expIds {

my $self=shift;
my %params=@_;

# 1 is the ''public'' userId
my $userId=$params{'userid'} || 1;

# gives a list of all non-''private'' expIds
my @allExpIds=Bio::KBase::ProteinInfoService::GenomicsUtils::queryList('
	SELECT e.id FROM microarray.Exp e
	JOIN microarray.Chip c ON (e.chipId=c.id)
	WHERE e.isPrivate="n"
	AND c.taxonomyId=?',$self->taxonomyId);

return resourceListRead($userId,'uarray',@allExpIds);

}

sub doesTaxHaveLogLevelData($$$)
{
	my $dbh = shift;
	my $tax_id = shift;
	my $exp_type = shift;
	
	my $hasLogLevelIds_q = qq^	select count(distinct r.id)
								from microarray.Chip c 
								inner join microarray.Exp e on c.id = e.chipId
								inner join microarray.Replicate r on r.expId = e.id
								where c.taxonomyId = ?
								and e.expType = ?
								and (r.numeratorLogLevelExperimentId is not null
								or r.denominatorLogLevelExperimentId is not null)^;
	my $hasLogLevelIds_qh = $dbh->prepare($hasLogLevelIds_q) 
								or die "Unable to prepare hasLogLevelIds_q - $hasLogLevelIds_q : ".
								$dbh->errstr();
	$hasLogLevelIds_qh->execute($tax_id,$exp_type) or die 
								"Unable to execute hasLogLevelIds_q - $hasLogLevelIds_q : ".
								$hasLogLevelIds_qh->errstr();
	my ($count) = $hasLogLevelIds_qh->fetchrow_array();
	if ($count > 0)
	{
		return 1;
	} 			
	else
	{
		return 0;
	}				
}

sub doesExpHaveLogLevelData($$)
{
	my $dbh = shift;
	my $exp_id = shift;
	
	my $hasLogLevelIds_q = qq^	select count(distinct r.id)
								from microarray.Chip c 
								inner join microarray.Exp e on c.id = e.chipId
								inner join microarray.Replicate r on r.expId = e.id
								where e.id = ?
								and (r.numeratorLogLevelExperimentId is not null
								or r.denominatorLogLevelExperimentId is not null)^;
	my $hasLogLevelIds_qh = $dbh->prepare($hasLogLevelIds_q) 
								or die "Unable to prepare hasLogLevelIds_q - $hasLogLevelIds_q : ".
								$dbh->errstr();
	$hasLogLevelIds_qh->execute($exp_id) or die 
								"Unable to execute hasLogLevelIds_q - $hasLogLevelIds_q : ".
								$hasLogLevelIds_qh->errstr();
	my ($count) = $hasLogLevelIds_qh->fetchrow_array();
	if ($count > 0)
	{
		return 1;
	} 			
	else
	{
		return 0;
	}				
}

return 1;

}


=back

=head1 AUTHORS

Eric Alm, Katherine Huang, Dylan Chivian, Wayne Huang, Marcin
Joachimiak, Keith Keller, Morgan Price, Paramvir Dehal, Adam Arkin

=cut

