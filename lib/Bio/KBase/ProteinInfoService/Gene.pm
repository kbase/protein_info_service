#!/usr/bin/env perl
package Bio::KBase::ProteinInfoService::Gene;
require Exporter;

# $Id: Gene.pm,v 1.129 2012/07/20 18:55:42 jkbaumohl Exp $

use strict;
use Carp;
use Time::HiRes;

# an assignment here is useless, but needs to be declared
# before the BEGIN block
my ($useFastBLAST,$useRTB);

BEGIN {
	# surprisingly, only need this in BEGIN; I guess it stays in
	# @INC after the BEGIN block terminates
	# turn off warnings in case the user hasn't defined SANDBOX_DIR
	#no warnings 'uninitialized';
	#use lib "$ENV{SANDBOX_DIR}/RegTransBase/perllib";
	#use lib "$ENV{SANDBOX_DIR}/fasthmm/lib";
	#use warnings;
	# this is just to test whether things exist
	# needs to be a require so that it's run-time, not compile-time
	#eval {
	#	require Bio::KBase::ProteinInfoService::RegTransBase::Integration::MicrobesOnline;
	#	require Bio::KBase::ProteinInfoService::RegTransBase::Search;
	#};

	# use RTB later unless eval had a problem with the above requires
	#$useRTB=1 unless ($@);

	#eval {
	#	require FastBLAST;
	#};

	# use FastBLAST later unless eval had a problem with the above requires
	#$useFastBLAST=1 unless ($@);

	# $debug is not available yet, so uncomment if you want to see the eval msg
	# warn $@ if $@;
}

# conditional use if--not available in earlier versions of perl
use if $useRTB, 'Bio::KBase::ProteinInfoService::GeneRTB';
use if $useRTB, 'Bio::KBase::ProteinInfoService::RegTransBase::Integration::MicrobesOnline';
use if $useRTB, 'Bio::KBase::ProteinInfoService::RegTransBase::Search';

use if $useFastBLAST, 'FastBLAST';
#use if $useFastBLAST, 'Args';

use Bio::KBase::ProteinInfoService::GenomicsUtils;
use Bio::KBase::ProteinInfoService::Scaffold;
use Bio::KBase::ProteinInfoService::Genome;
use Bio::KBase::ProteinInfoService::Description;
use Bio::KBase::ProteinInfoService::Regulon;
use Bio::KBase::ProteinInfoService::Vector;
use Bio::KBase::ProteinInfoService::Browser::Defaults;

sub new;

# Constructor for gene object. Returns Gene object.  Parameters should
# be specified in a form locusId => x, $start => ss and so on:
# 
#  scaffoldRef - reference to Scaffold object, 
#  begin, end, strand, locusId, version, posId, cogInfoId
#--------------------------------------------------------------
# The following functions return basic info about genes and are
# relatively self-explanatory.

sub start();
sub stop(); 
sub begin();
sub loadRtbDetails;
sub rtb();
sub end();
# start/stop returns the position of the start/stop codon for each Locus.
# begin/end returns the first and last bp in the gene (begin<end unless wrapping around 0)

sub length(); # in aa not bases
sub strand(); # Returns '+' or '-'
sub locusId();
sub posId();
sub scaffoldId();
sub taxonomyId();
sub taxonomyName();
sub taxonomyShort();
sub type(); # Protein-coding, rRNA, etc. etc.
sub isPseudo();
sub isProtein();
sub istRNA();
sub isrRNA();
sub scaffoldInfo();
sub toString(); # Returns some information about the gene.
sub gff; #returns a brief description of the gene in GFF format
#sub annotation();
#sub annotationRef();# Returns list/reference to a list of annotation objects for the gene
sub geneName(); #return synonym type==0
sub synonym(); # Returns reference to a list of synonyms for the gene.
# Alternatively, synonym(x) returns just the synonym of type x (as a list)

sub cogSymbol(); #  returns COG gene name
sub cogFunCode();# Returns Riley funtional code for COGs
sub cogDesc(); #Returns the description of COG
sub cog(); # Returns the ID, but only numbers
sub cogId(); # Returns the ID in this format COGnnnn
sub ec(); #returns a ref to array of EC numbers
sub go(); #returns a ref to array of GO terms
sub ipr(); #returns a ref to array of InterPro domains
sub tigr(); #returns a ref to array of TIGRfams
sub tigrRoles(); #returns a ref to array of TIGR roles based on TIGRFam results
sub tigrDetails(); #returns a ref to array of TIGRfam info in detail
sub tigrSymbols(); #returns a ref to an array of TIGR gene symbols (gene names by TIGRFAM)
sub tigrFunCat(); #returns the tigr function category (tigr roles) from the TIGR CMR website (one to one mapping)
sub tigrMainFun(); # returns the tigr main func. category
sub tigrSubFun(); # returns the tigr sub func. category
sub pdbs(); #returns a ref to array of PDBs
sub seedId; # returns the SEED fig ID
sub bestBlastpRef(); #returns the best blastp hit, bestBlastpRef(1) to retrieve best non-paralog hit
sub BestHitTaxa(); # returns the best hit within the given taxa, as taxonomyId/locusId/score, or ()
sub blastScores(); # returns the score of the match to the given genes
sub codonUsageTable();
sub addCodonUsage();
sub isPlasmid();
sub description();
#sub descriptionRef(); # Returns list/reference to a list of descriptions for the gene.
sub scaffold(); # Returns reference to scaffold object this gene belongs to.
sub evidence(); # gets the evidence (note this is not cached - requires db access each time)
sub maData; # returns a count of rows in MeanLogRatio expType = RNA
sub fitnessData; # returns a count of rows in MeanLogRatio expType = Fitness
sub expIds; # returns $genome->expIds

sub papers($); # list of pubmedids (detailed only)
sub LocusPapers($); # same, but takes a locusId not a gene ojbect
sub characterizedSubset($$); # subset of locusIds; optionally get only bidir-characterized
sub pdbStructuresSubset($); # subset of locusIds with PDBs >= 97%

#--------------------------------------------------------------
# Sequence accession methods

sub dna(); # Returns nucleotide sequence (CDS) of the gene
sub protein(); # Returns amino acid sequence
sub crc64; # Compute the CRC of a gene
sub ntcrc64; # Compute the CRC on the nucleotide sequence
sub transcript; # Returns the transcript sequence 	 
sub exonCoords; # Returns the coordinates of the exons, if available 	 
sub cdsCoords; # Returns the coordinates of the CDS, if available

sub getUpstream; # Returns upstream region for this gene
#parameters:
#downstream - if downstream is true, returns downstream region
#length - how many bps? (default -> 150)
#offset - offset by how many bp upstream(downstream)? (default -> 0)
#         an offset of -3 will return a sequence including the
#         start(stop) codon
#truncate - if truncate is true, remove overlap with adjacent coding regions
#NOTE - this function no longer tries to find the first gene in the operon
#use [$gene->getOperon()]->[0]->getUpstream() instead


#--------------------------------------------------------------
# These functions return info on how this gene is related to others in
# the DB.

sub orthologs($);
# return an array of ortholog locusIds

sub getOrthologListRef($);
# Only parameter is self

sub getOrthologList($);
# Returns a list of orthologous genes

sub getOrtholog($$);
# Returns the ortholog from specified taxonomyId, or undef

# return a reference to a hash of locusId => hash, each hash has
# taxonomyId, locusId, etc.
# This has replaced selecting orthologs from the Ortholog table
sub treeOrthologs;

sub getBlastPHitsRef();
# Returns a reference to a list of hits
# Each hit has query, subject, identity, alignLength,
# mismatch, gap, qBegin, qEnd, sBegin, sEnd, evalue, score
# (No version information -- active version of locus is presumed).


#--------------------------------------------------------------

sub nextGene();
sub previousGene();
# Returns object reference to the next/previous gene along the
# chromosome.

sub upstreamGene();
sub downstreamGene();
# Similar to next and previous, but returns ref to the next gene
# up/downstream on the same strand.  If there are no more adjacent
# genes on the same strand, returns undef.

sub getOperon;
#returns a list of genes known or predicted to be in an operon
#with the query gene (including the query itself)
#if the map parameter is defined (and evaluates to true), then
#a hash of lists is returned, where each list is a single operon
#including the query, and the indexes are tuIds

#--------------------------------------------------------------
# Internal functions used only by the module

#sub getDescription($);
# Returns a list of description objects based descriptionId
# Parameters:
#   descriptionId   		  

sub setIndex($);
# Sets the index of the gene in the list of genes ordered by begin
# position in the scaffold

sub index();
# Returns index of the gene in a list of genes

sub indexAssigned();
# Returns true if index is assigned to the gene

#--------------------------------------------------------------

sub regulon; #returns the regulon object
sub operonId; #returns the operon ID
sub uniprot; # returns the uniprot ID


my $DATA_DIR = "/data/genomics/data/genomes/";

sub new
{
    my %params = @_;#%{$_[0]};

    croak "No locusId declared in Bio::KBase::ProteinInfoService::Gene::new()" unless defined $params{'locusId'};
    my $self = {};
    bless $self;
    
    #get the best version if none specified
    if (! defined($params{'version'})){
	my $qRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query( qq{SELECT version FROM Locus WHERE locusId=$params{'locusId'} AND priority=1} );
	return undef if @$qRef == 0;
	$params{'version'} = ${$qRef->[0]}[0];
    }
    $self->{locusId_} = $params{'locusId'};
    $self->{version_} = $params{'version'};

    if (! ( defined($params{'begin'}) &&
	    defined($params{'end'}) &&
	    defined($params{'strand'}) &&
	    defined($params{'posId'}) &&
	    defined($params{'type'}) )){
	my $qRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query( qq{SELECT p.begin, p.end, p.strand, o.type, o.posId, c.cogInfoId FROM Position p JOIN Locus o USING (posId) LEFT JOIN COG c USING (locusId, version) WHERE o.locusId=$params{'locusId'} AND o.version = $params{'version'}} ) if $params{'version'};
	return undef if @$qRef == 0;

	( $self->{begin_},
	  $self->{end_},
	  $self->{strand_},
	  $self->{type_},
	  $self->{posId_},
	  $self->{cog_}
 	 ) = @{$qRef->[0]};

	return $self;
    }

    $self->{scaffold_} = $params{'scaffoldRef'};
    $self->{scaffold_} = Bio::KBase::ProteinInfoService::Scaffold::new(scaffoldId => $params{'scaffoldId'})
        if (!defined $self->{scaffold_} && exists $params{'scaffoldId'});
    $self->{begin_} = $params{'begin'};
    $self->{end_} = $params{'end'};
    $self->{strand_} = $params{'strand'};
    $self->{posId_} = $params{'posId'};
    $self->{type_} = $params{'type'};
    $self->{cog_} = defined( $params{'cogInfoId'} ) ? $params{'cogInfoId'} : "";
    $self->{index_} = $params{'index'};
    $self->{synonym_} = $params{'synonym'};
    $self->{orthologListRef_} = $params{'orthologListRef'} if exists $params{'orthologListRef'};
    $self->{ec_} = $params{'ec'};
    $self->{ecNum_} = $params{'ecNum'};
    $self->{go_} = $params{'go'};
    $self->{ipr_} = $params{'ipr'};
    $self->{cogDesc_} = $params{'cogDesc'};
    $self->{cogFun_} = $params{'cogFun'};
    $self->{bestBlastp_} = $params{'bestBlastp'};
    $self->{description_} = $params{'description'};
    $self->{rtbLoaded_} = 0;
    $self->{rtb} = {};

    return $self;
}

sub rtb()
{
	my $self = shift;

	loadRtbDetails()
		if ( $self->{rtbLoaded_} == 0 );

	return $self->{rtb};
}

sub loadRtbDetails
{
	my $self = shift;

	if ( $self->{rtbLoaded_} == 0 )
	{
		$self->{rtb}->{articles}=[];
		$self->{rtb}->{regulators}=[];
		$self->{rtb}->{search} = Bio::KBase::ProteinInfoService::RegTransBase::Search->new()
			if ( !exists( $self->{rtb}->{search} ) );
		$self->{rtb}->{integration} = Bio::KBase::ProteinInfoService::RegTransBase::Integration::MicrobesOnline->new()
			if ( !exists( $self->{rtb}->{integration} ) );

		my $locusId = $self->{locusId_};
		my $seqfeature_id = $self->{rtb}->{integration}->get_regtransbase_id( -locusId => $locusId );

		# need this, or genes will retrieve all papers
		return $self->{rtb} unless ($seqfeature_id);

		my $geneSeqFeats = $self->{rtb}->{search}->get_seqdb_seqfeature( -seqfeature_id => $seqfeature_id );
		print STDERR "rtb seqfeature_id $seqfeature_id returns more than one gene seq feature record!! using first"
			if ( scalar(@{$geneSeqFeats}) > 1 );
		$self->{rtb}->{seqfeature} = $geneSeqFeats->[0];
		$self->{rtb}->{accession} = $self->{rtb}->{search}->get_seqfeature_accession( $geneSeqFeats->[0] );
		$self->{rtb}->{articles} = $self->{rtb}->{search}->get_articles( -seqfeature_id => $seqfeature_id, -type => 'gene' );
		foreach my $art ( @{$self->{rtb}->{articles}} )
		{
			# pre-load experiment info
			$art->experiments();
		}
		$self->{rtb}->{numArticles} = scalar( @{$self->{rtb}->{articles}} );
		$self->{rtb}->{regulators} = Bio::KBase::ProteinInfoService::GeneRTB::getRTBRegulators( $self->{rtb}->{search}, $seqfeature_id, 'gene' );

		$self->{rtbLoaded_} = 1;
	}

	return $self->{rtb};
}

sub begin() 
{
    my $self = shift;
    return $self->{begin_};
}

sub end()
{
    my $self = shift;
    return $self->{end_};
}

sub start() 
{
    my $self = shift;
    return $self->{strand_} eq "+" ? $self->{begin_} : $self->{end_};
}

sub stop()
{
    my $self = shift;
    return $self->{strand_} eq "+" ? $self->{end_} : $self->{begin_};
}

# Note -- result is in a.a. not nucleotides.
# This does NOT return correct results for loci that wrap around the origin.
sub length(){
    my $self = shift;
    return 0 if $self->{type_} != 1;
    return ($self->{end_} - $self->{begin_} + 1)/3;
    &Bio::KBase::ProteinInfoService::GenomicsUtils::warn("Gene length not multiple of 3 in Bio::KBase::ProteinInfoService::Gene::length()",2);
}

sub strand() 
{
    my $self = shift;
    return $self->{strand_};
}

sub locusId()
{
    my $self = shift;
    return $self->{locusId_};
}

sub version()
{
    my $self = shift;
    return $self->{version_};
}

sub posId()
{
    my $self = shift;
    return $self->{posId_};
}

sub toString() 
{
    my $self = shift;
    return "[".$self->{locusId_}."] ".$self->{begin_}."..".$self->{end_}." ".$self->{strand_};
}

sub dna() 
{
    my $self = shift;
    if( !defined($self->{dna_} ) ) {
	my $locusId=$self->{locusId_};
	my $version=$self->{version_}; 
	($self->{dna_}) = Bio::KBase::ProteinInfoService::GenomicsUtils::dbh()->selectrow_array( qq/SELECT sequence FROM LocusSeq WHERE locusId=$locusId and version=$version/ );
    }

    return $self->{dna_};
}

sub transcript {

	my $self = shift;
	if( !defined($self->{transcript_} ) )
	{
		my $locusId=$self->{locusId_};
		my $version=$self->{version_};
		($self->{transcript_}) = Bio::KBase::ProteinInfoService::GenomicsUtils::dbh()->selectrow_array(
			qq/SELECT sequence FROM TranscriptSeq WHERE locusId=$locusId and version=$version/ );
	}

	return $self->{transcript_};
}
	  	 
sub cdsCoords {

	my $self = shift;
	if( !defined($self->{cdsCoords_} ) )
	{
		my $locusId=$self->{locusId_};
		my $version=$self->{version_};
		($self->{cdsCoords_}) = Bio::KBase::ProteinInfoService::GenomicsUtils::dbh()->selectrow_array(
			qq/SELECT cdsCoords FROM Locus WHERE locusId=$locusId and version=$version/ );
	}
	return $self->{cdsCoords_};
}
	  	 
sub exonCoords { 	 

	my $self = shift;
	if( !defined($self->{exonCoords_}) )
	{
		my $locusId=$self->{locusId_};
		my $version=$self->{version_};
		($self->{exonCoords_}) = Bio::KBase::ProteinInfoService::GenomicsUtils::dbh()->selectrow_array(
			qq/SELECT exonCoords FROM Locus WHERE locusId=$locusId and version=$version/ );
	} 	 

	return $self->{exonCoords_}; 	 
}

# hash of codons to one-letter amino acid codes
sub codonUsageTable() {
    my @list = (TCA => 'S',TCG => 'S',TCC => 'S',TCT => 'S',
		TTT => 'F',TTC => 'F',TTA => 'L',TTG => 'L',
		TAT => 'Y',TAC => 'Y',TAA => '*',TAG => '*',
		TGT => 'C',TGC => 'C',TGA => '*',TGG => 'W',
		CTA => 'L',CTG => 'L',CTC => 'L',CTT => 'L',
		CCA => 'P',CCG => 'P',CCC => 'P',CCT => 'P',
		CAT => 'H',CAC => 'H',CAA => 'Q',CAG => 'Q',
		CGA => 'R',CGG => 'R',CGC => 'R',CGT => 'R',
		ATT => 'I',ATC => 'I',ATA => 'I',ATG => 'M',
		ACA => 'T',ACG => 'T',ACC => 'T',ACT => 'T',
		AAT => 'N',AAC => 'N',AAA => 'K',AAG => 'K',
		AGT => 'S',AGC => 'S',AGA => 'R',AGG => 'R',
		GTA => 'V',GTG => 'V',GTC => 'V',GTT => 'V',
		GCA => 'A',GCG => 'A',GCC => 'A',GCT => 'A',
		GAT => 'D',GAC => 'D',GAA => 'E',GAG => 'E',
		GGA => 'G',GGG => 'G',GGC => 'G',GGT => 'G');
    return @list;
}

# assumes all of the entries in the hash exist
# returns 0 if the gene has a frameshift preventing codon usage determination
# or is not protein-coding
sub addCodonUsage() {
    my ($self, $hash) = @_;
    my $length = $self->end() - $self->begin() + 1;
    return 0 if ($length % 3 != 0) || $self->type() != 1;
    my $seq = $self->dna();
    for (my $i = 0; $i < CORE::length($seq); $i += 3) {
	$hash->{substr($seq, $i, 3)}++;
    }
    return 1;
}

sub protein()
{
    my $self = shift;
    if ($self->{type_} != 1) { return undef; }

    if( !defined($self->{protein_} ) ) {
	my $locusId=$self->{locusId_};
	my $version=$self->{version_}; 
	($self->{protein_}) = Bio::KBase::ProteinInfoService::GenomicsUtils::dbh()->selectrow_array( qq/SELECT sequence FROM AASeq WHERE locusId=$locusId and version=$version/ );
    }

    return $self->{protein_};
}

sub crc64
{
	my $self=shift;
	return Bio::KBase::ProteinInfoService::GenomicsUtils::crc64($self->protein);
}

sub ntcrc64
{
	my $self=shift;
	return Bio::KBase::ProteinInfoService::GenomicsUtils::crc64($self->dna);
}

#sub annotation() 
#{
#    return @{&annotationRef(@_)};
#}

#sub annotationRef()
#{
#    my $self = shift;
#    if( !defined( $self->{annotation_} ) ) {
#	$self->{annotation_} = getDescription( $self->{locusId_} );
#    }

#    return $self->{annotation_};
#}

sub description() 
{
    my $self = shift;
    if (!defined($self->{description_})){	
	my $locusId=$self->{locusId_};
	my $version=$self->{version_}; 
	my $dataR = Bio::KBase::ProteinInfoService::GenomicsUtils::query( qq/SELECT description, source FROM Description WHERE locusId=$locusId and version=$version/ );	
	$self->{description_} = ($dataR->[0])?$dataR->[0][0]." (".$dataR->[0][1].")":"";
    }
    return $self->{description_};
}

#sub descriptionRef()
#{
#    my $self = shift;
#    my $annotationList = $self->annotationRef();
#    my @description;
#    foreach my $annotation (@$annotationList) {
#	push @description, $annotation->description();
#    }
#    return \@description;
#}

sub geneName(){
    my $self = shift;
    return $self->synonym->{0};
}
sub synonym() 
{
    my $self = shift;
    my @params;
    if (@_ > 0){
	@params = @_;
    }
    my $locusId = $self->{locusId_};
    my $version = $self->{version_};
    if( !defined( $self->{synonym_} ) ) {
	my $synRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query( qq{SELECT DISTINCT name,type FROM Synonym WHERE locusId=$locusId and version=$version} );
	my %syn = map {$_->[1],$_->[0]} @{$synRef};
	$self->{synonym_} = \%syn;

    }

    # check externalId field too from Locus for metagenome genes
    if ($defaults->{showMeta} == 1)
    {
	    my $externalRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query( qq{SELECT DISTINCT externalId,evidence FROM Locus WHERE locusId=$locusId and version=$version} );
	    my %ext = map {$_->[1],$_->[0]} @{$externalRef};
	    foreach my $external_db (keys %ext) {
			my $externalId = $ext{$external_db};
			$self->{synonym_}{$external_db} = $externalId;
	    }
	}
    if (@params){
	my @results = ();
	foreach my $type (@params){
	    if (defined($self->{synonym_}{$type})){
		push @results, $self->{synonym_}{$type};
    	}
    }
	return @results;
    }

    return $self->{synonym_};
}

sub ec(){
    my $self = shift;
    my $locusId = $self->{locusId_}; 
    my $version = $self->{version_};
    if (!defined( $self->{ec_} ) ){
	my $ecRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query( qq{SELECT Locus2Ec.ecNum, ECInfo.name, Locus2Ec.evidence FROM Locus2Ec LEFT JOIN ECInfo ON Locus2Ec.ecNum=ECInfo.ecNum WHERE locusId='$locusId' AND version=$version} );
	my @ec = ();
	my @ecNum = ();
	if ($ecRef){
	    foreach (@$ecRef){
		my $evidence = defined($_->[2])?$_->[2]:"KEGG";
		my $ecName = defined($_->[1])?$_->[1]:"";
		push @ec, $_->[0]."\t".$ecName."\t"."(".$evidence.")" if $_->[0];
		push @ecNum, $_->[0];
	    }

	}
	$self->{ec_} = \@ec;
	$self->{ecNum_} = \@ecNum;
    }
    return $self->{ec_};
	
	
}
sub ecNum{
    my $self = shift;
    if (!defined($self->{ec_})){$self->ec();}
    return @{$self->{ecNum_}};
}
sub ipr(){
    my $self = shift;
    my $locusId = $self->{locusId_}; 
    my $version = $self->{version_};
    if (!defined( $self->{ipr_} ) ){
	my $iprRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query( qq{SELECT Locus2Ipr.iprId, iprName FROM Locus2Ipr, IPRInfo WHERE Locus2Ipr.locusId='$locusId' AND Locus2Ipr.iprId=IPRInfo.iprId} );
	my @ipr = ();
	if ($iprRef){
	    foreach (@$iprRef){
		push @ipr, $_->[0].": ".$_->[1];
	    }

	}
	$self->{ipr_} = \@ipr;
    }
    return $self->{ipr_};
	
	
}
sub go(){
    my $self = shift;
    my $locusId = $self->{locusId_}; 
    my $version = $self->{version_};
    if (!defined( $self->{go_} ) ){
	my $goRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query( qq{SELECT t.term_type, t.acc, t.name, o.evidence FROM Locus2Go o, term t WHERE o.locusId='$locusId' AND o.goId=t.id ORDER BY term_type} );
	my @go = ();
	if ($goRef){
	    foreach (@$goRef){
		$_->[0] =~ s/molecular_function/[M]/; 
		$_->[0] =~ s/cellular_component/[C]/;
		$_->[0] =~ s/biological_process/[B]/;
		push @go, $_->[0]." ".$_->[1]." ".$_->[2]." "."(".$_->[3].")";
	    }

	}
	$self->{go_} = \@go;
    }
    return $self->{go_};
	
	
}
sub tigrFunCat(){
    my $self = shift;
    my $locusId = $self->{locusId_};
    if (!defined($self->{tigrFunCat_})){
	    # deprecating Locus2TigrFunCat table
#	my $Ref = GenomicsUtils::query(qq{SELECT mainRole, subRole, evidence from Locus2TigrFunCat where locusId=$locusId});
#	if ($Ref->[0][0]){
#	    $self->{tigrFunCatEvidence_} = $Ref->[0][2];
#	    $self->{tigrFunCatEvidence_} = 'VIMSS'.$self->{tigrFunCatEvidence_}
#	    	if ($self->{tigrFunCatEvidence_}=~/^\d+$/);
#	    $self->{tigrFunCat_} = $Ref->[0][0].":".$Ref->[0][1]
#	    	. ' (from ' . $self->{tigrFunCatEvidence_} . ')';
#	    $self->{tigrMainFun_} = $Ref->[0][0];
#	    $self->{tigrSubFun_} = $Ref->[0][1];
#	} else {
		my $Ref = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{
			SELECT main.description, sub.description, 'FastHMM'
			FROM TIGRroles main
			JOIN TIGRInfo ti ON (main.roleId=ti.roleId AND main.level='main')
			JOIN TIGRroles sub ON (sub.roleId=ti.roleId AND sub.level!='main')
			JOIN Locus2Domain ld ON (ld.domainId=ti.tigrId)
			JOIN Locus l USING (locusId,version)
			JOIN Scaffold s USING (scaffoldId)
			WHERE s.isActive=1
			AND l.priority=1
			AND l.locusId=? },$locusId);
	return $self->{tigrFunCat_} unless $Ref->[0][0];
	    $self->{tigrFunCat_} = $Ref->[0][0].":".$Ref->[0][1];
	    $self->{tigrMainFun_} = $Ref->[0][0];
	    $self->{tigrSubFun_} = $Ref->[0][1];
	    $self->{tigrFunCatEvidence_} = 'HMMER';
#  	 }
    }
    return $self->{tigrFunCat_};

}
sub tigrMainFun(){
    my $self = shift;
    $self->tigrFunCat();
    return $self->{tigrMainFun_};
}
sub tigrSubFun(){
    my $self = shift;
    $self->tigrFunCat();
    return $self->{tigrSubFun_};
}
sub tigr(){
    my $self = shift;
    my $locusId = $self->{locusId_};
    my $version = $self->{version_};
    if (!defined( $self->{tigr_} ) ){
	    # left join Tree; in theory there may not be a tree
	    # (though this should be rare)
	    # also left join TIGRroles; they may not exist
		my $tigrQuery= qq{
			SELECT ti.tigrId, ti.definition, ti.geneSymbol,
			main.description, subR.description, t.treeId
			FROM Locus2Domain ld
			JOIN TIGRInfo ti ON (ti.tigrId=ld.domainId)
			LEFT JOIN TIGRroles main ON
		       		(ti.roleId=main.roleId AND main.level='main')
			LEFT JOIN TIGRroles subR ON
		       		(ti.roleId=subR.roleId AND subR.level='sub1')
			LEFT JOIN Tree t ON (t.name=ld.domainId)
			WHERE locusId=$locusId AND version=$version
			AND t.type='TIGRFAMs'
			ORDER BY tigrId
			};
        my $tigrRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query($tigrQuery);
	my @tigr = ();
	my @tigrRoles = ();
	my @tigrDetails = ();
	my @tigrSymbols = ();
	my @tigrRef = ();
	if ($tigrRef){
	    foreach (@$tigrRef){
		    #push @tigr, join " ", $_->[0], $_->[1], "[$_->[2]]";
		my $tigrTxt=join " ", $_->[0], $_->[1];
	        $tigrTxt.=" [$_->[2]]" if $_->[2];;
		push @tigr,$tigrTxt;
		    #push @tigr, join " ", $_->[0], $_->[1], "[$_->[2]]";
		push @tigrSymbols, $_->[2];
		push @tigrRoles, join ":", $_->[3], $_->[4];
		push @tigrDetails, join " ", $_->[0], $_->[1], "[$_->[2]]", "($_->[3]: $_->[4])";
		push @tigrRef, {
			tigrId	=>	$_->[0],
			tigrDefinition	=>	$_->[1],
			tigrGeneSymbol	=>	$_->[2],
			tigrMainDesc	=>	$_->[3],
			tigrSubDesc	=>	$_->[4],
			treeId	=>	$_->[5],
			};
	    }
	}

	$self->{tigr_} = \@tigr;
	$self->{tigrRoles_} = \@tigrRoles;
	$self->{tigrDetails_} = \@tigrDetails;
	$self->{tigrSymbols_} = \@tigrSymbols;
	$self->{tigrRef_} = \@tigrRef;
    }

    return $self->{tigr_};
}
sub tigrDetails(){
    my $self = shift;
    if (!defined($self->{tigrDetails_})){
	$self->tigr();
    }
    return $self->{tigrDetails_};
}
sub tigrRef(){
    my $self = shift;
    if (!defined($self->{tigrRef_})){
	$self->tigr();
    }
    return $self->{tigrRef_};
}
sub tigrRoles(){
    my $self = shift;
    if (!defined($self->{tigrRoles_})){
	$self->tigr();
    }
    return $self->{tigrRoles_};
}
sub tigrSymbols(){
    my $self = shift;
    if (!defined($self->{tigrSymbols_})){
	$self->tigr();
    }
    return $self->{tigrSymbols_};
}
sub cogSymbol(){
    my $self = shift;
    $self->{cogSymbol_} = "" unless $self->{cog_};
    if (!defined($self->{cogSymbol_})){
	$self->cogDesc();
    }
    return $self->{cogSymbol_};

}
sub cogFunCode()
{
    my $self = shift; 
    $self->{cogFun_} = "" unless $self->{cog_};
    if( !defined($self->{cogFun_}) ) {
	$self->cogDesc();
    }
    return $self->{cogFun_};
}
sub cogDesc()
{
    my $self = shift;
    $self->{cogDesc_} = "" unless $self->{cog_};
    
    if( !defined($self->{cogDesc_}) ) {
	my $cogInfoId = $self->cog();
	my $funRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query( qq/SELECT funCode, description, geneName from COGInfo WHERE cogInfoId=$cogInfoId/);
	$self->{cogFun_} = defined($funRef->[0][0])?$funRef->[0][0]:"";
	$self->{cogDesc_} = defined($funRef->[0][1])?$funRef->[0][1]:"";
	$self->{cogSymbol_} =defined($funRef->[0][2])?$funRef->[0][2]:"";
    }
    return $self->{cogDesc_};
}
sub cog()
{
    my $self = shift;
    if( !defined($self->{cog_}) ) {
		my $locusId=$self->{locusId_}; 
		my $cogRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{SELECT c.cogInfoId from Locus o left join COG c on (o.locusId=c.locusId and o.version=c.version) WHERE o.locusId=$locusId });
		$self->{cog_} = defined($cogRef->[0][0])?$cogRef->[0][0]:'';
    }

    return $self->{cog_};
}

sub cogId()
{
    my $self = shift;
    if ( !defined($self->{cog_}) ) {
	$self->cog();
    }
    my $cogId;
    if ($self->{cog_}){
	($cogId = $self->{cog_}+10000) =~ s/^1(\d+)/COG$1/;
    }
    return $cogId;
}


sub seedId {
	my $self = shift;
	return $self->{seedId_} if (exists $self->{seedId_});

	my $locusId=$self->{locusId_}; 
	my $seedRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{
		SELECT s.seedId from Locus l left join Locus2Seed s
		USING (locusId)
		WHERE s.locusId=?
		},$locusId);

	$self->{seedId_} = $seedRef->[0][0];
	return $self->{seedId_};
}


sub pdbs(){
    my $self = shift;
    my %params = @_;
    my $locusId = $self->{locusId_};
    my $version = $self->{version_};

    my $refresh = undef;
    if (!defined( $self->{pdbs_} ) ){
	$refresh = 'TRUE';
    }
    else {
	foreach my $k (keys %params) {
	    if ($params{$k} ne $self->{pdbs_params_}->{$k}) {
		$refresh = 'TRUE';
		last;
	    }
	}
    }

    if ($refresh) {
	$self->{pdbs_}        = undef;
	$self->{pdbs_params_} = undef;
	foreach my $k (keys %params) {
	    $self->{pdbs_params_}->{$k} = $params{$k};
	}

	my $pdbQuery = qq{
	    SELECT lp.pdbId, lp.pdbChain, lp.seqBegin, lp.seqEnd, lp.pdbBegin, lp.pdbEnd, lp.identity, lp.alignLength, lp.mismatch, lp.gap, lp.evalue, lp.evalueDisp, lp.score
	    FROM Locus2Pdb lp
	    WHERE lp.locusId=$locusId AND lp.version=$version
	};
	if ($params{'self'} && $params{'self'} !~ /^F/i) {
	    $pdbQuery .= qq{AND lp.identity >= 97.00};
	}

        my $pdbRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query($pdbQuery);
	my @pdbs = ();
	if ($pdbRef){

	    my @retained_pdbs = ();
	    if ((! $params{'non_redundant'} || $params{'non_redundant'} =~ /^F/i) &&
		! $params{'target_pdb'}
		) {
		@retained_pdbs = @$pdbRef;
	    }
	    else {
		my %top_pdbs      = ();
		my %top_idents    = ();
		my %top_recs      = ();
		my %keep_recs     = ();

		my $min_cov       = 15;  # 20?
		my $ident_gap     = 5;

		my $pdbId_i       = 0;
		my $pdbChain_i    = 1;
		my $identity_i    = 6;
		my $alignLength_i = 7;
		foreach my $pdb (sort {
		    $b->[$identity_i]    <=> $a->[$identity_i] ||
		    $b->[$alignLength_i] <=> $a->[$alignLength_i]  ||
		    $a->[$pdbId_i].$a->[$pdbChain_i] cmp $b->[$pdbId_i].$b->[$pdbChain_i]
		} @$pdbRef) {

		    my $new_pdb = +{ 'pdbId'       => $pdb->[0],
				     'pdbChain'    => $pdb->[1],
				     'seqBegin'    => $pdb->[2],
				     'seqEnd'      => $pdb->[3],
#				     'pdbBegin'    => $pdb->[4],
#				     'pdbEnd'      => $pdb->[5],
				     'identity'    => $pdb->[6],
#				     'alignLength' => $pdb->[7],
#				     'mismatch'    => $pdb->[8],
#				     'gap'         => $pdb->[9],
#				     'evalue'      => $pdb->[10],
#				     'evalueDisp'  => $pdb->[11],
#				     'score'       => $pdb->[12]
				     };

		    my $pdb_id_chain = $new_pdb->{pdbId}.$new_pdb->{pdbChain};
		    my $n_ident      = $new_pdb->{identity};
		    my $n_beg        = $new_pdb->{seqBegin};
		    my $n_end        = $new_pdb->{seqEnd};
		    my $n_range      = "$n_beg-$n_end";

		    if (! %top_pdbs) {
			$top_pdbs{$n_range}   = $pdb_id_chain;
			$top_idents{$n_range} = $n_ident;
			$top_recs{$n_range}   = $pdb;
		    } 
		    else {
			my $new_beat    = undef;
			my $new_keep    = undef;
			my $new_keep_range = undef;
			my @beat_ranges = ();
			my @keep_ranges = ();

			foreach my $o_range (keys %top_pdbs) {
			    my ($o_beg, $o_end) = split (/\-/, $o_range);
			    if ($n_beg <= $o_end && $n_end >= $o_beg) {  # overlap
				my $n_cov = $n_end - $n_beg + 1;
				my $o_cov = $o_end - $o_beg + 1;
				my $hi_beg = ($n_beg > $o_beg) ? $n_beg : $o_beg;
				my $lo_end = ($n_end < $o_end) ? $n_end : $o_end;
				my $overlap_len = $lo_end - $hi_beg + 1;

				# only compare heavily overlapping coverage
				next if ($overlap_len < $n_cov - $min_cov &&
					 $overlap_len < $o_cov - $min_cov);

				$n_cov -= $overlap_len;
				$o_cov -= $overlap_len;

				# clear cut case of old beating new
				if ($n_ident <= $top_idents{$o_range}) {
				    if ($n_cov < $min_cov) {
					if ($n_ident < $top_idents{$o_range} - $ident_gap) {
					    $new_beat = 'TRUE';
					} else {
					    $new_beat = 'TRUE';
					    $new_keep = 'TRUE';
					    $new_keep_range = $o_range;
					}
					last;
				    }
				}
				# clear cut case of new beating old
				elsif ($top_idents{$o_range} < $n_ident) {
				    if ($o_cov < $min_cov) {
					if ($top_idents{$o_range} < $n_ident - $ident_gap) {
					    push (@beat_ranges, $o_range);
					} else {
					    push (@keep_ranges, $o_range);
					}
				    }
				}
			    }
			}

			# clean up beat pdbs
			if (@beat_ranges) {
			    foreach my $beat_range (@beat_ranges) {
				delete $top_pdbs{$beat_range};
				delete $top_idents{$beat_range};
				delete $top_recs{$beat_range};
				delete $keep_recs{$beat_range};
			    }
			}
			
			# move over beaten but close pdbs
			if (@keep_ranges) {
			    foreach my $keep_range (@keep_ranges) {
				if (! $keep_recs{$n_range}) {
				    $keep_recs{$n_range} = +[];
				} 
				push (@{$keep_recs{$n_range}}, $top_recs{$keep_range});
				# move recs from old range to new range
				if ($keep_range ne $n_range) {
				    push (@{$keep_recs{$n_range}}, @{$keep_recs{$keep_range}});
				    delete $keep_recs{$keep_range};
				}
			    }
			}
			
			if ($new_keep) {  # not a top hit, but worth keeping
			    if (! $keep_recs{$new_keep_range}) {
				$keep_recs{$new_keep_range} = +[];
			    }
			    push (@{$keep_recs{$new_keep_range}}, $pdb);
			}

			# add new pdb if beat old pdb or offers enough new coverage
			if (@beat_ranges || @keep_ranges || ! $new_beat) {
			    $top_pdbs{$n_range}   = $pdb_id_chain;
			    $top_idents{$n_range} = $n_ident;
			    $top_recs{$n_range}   = $pdb;
			}
		    }
		}
		
		
		if (! $params{target_pdb}) {         # store the top pdbs
		    foreach my $range (keys %top_recs) {
			push (@retained_pdbs, $top_recs{$range});
		    }
		}
		else {    # store kept pdbs that correspond to target pdb
		    my %target_ranges = ();
		    my %target_idents = ();
		    foreach my $range (keys %top_recs) {
			if ($top_pdbs{$range} eq $params{target_pdb}) {
			    push (@retained_pdbs, $top_recs{$range});
			    $target_ranges{$range} = 1;
			    $target_idents{$range} = $top_idents{$range};
			}
		    }
		    foreach my $range (keys %keep_recs) {
			next if (! $target_ranges{$range});
			foreach my $pdb (@{$keep_recs{$range}}) {
			    next if ($pdb->[$identity_i] < $target_idents{$range} - $ident_gap);
			    push (@retained_pdbs, $pdb);
			}
		    }
		}
		#@retained_pdbs = @$pdbRef;	# DEBUG
	    }


	    foreach (@retained_pdbs){
		
		my $pdbId    = $_->[0];
		my $pdbChain = $_->[1];
		
		# fill entry
		my $new_pdb = +{ 'pdbId'       => $_->[0],
				 'pdbChain'    => $_->[1],
				 'seqBegin'    => $_->[2],
				 'seqEnd'      => $_->[3],
				 'pdbBegin'    => $_->[4],
				 'pdbEnd'      => $_->[5],
				 'identity'    => $_->[6],
				 'alignLength' => $_->[7],
				 'mismatch'    => $_->[8],
				 'gap'         => $_->[9],
				 'evalue'      => $_->[10],
				 'evalueDisp'  => $_->[11],
				 'score'       => $_->[12],
			     };
		
		# get alt pdbs
		if ($params{'get_alt_pdbs'} && $params{'get_alt_pdbs'} !~ /^F/i) {
		    my $pdbIdRep = $pdbId;
		    my $pdbChainRep = $pdbChain;
		    my $pdbRepQuery= qq{
		        SELECT pr.pdbId, pr.pdbChain
			FROM PdbReps pr
			WHERE pr.pdbIdRep='$pdbIdRep' AND pr.pdbChainRep='$pdbChainRep'
		    };
		    my @altIds = ();
		    my @altChains = ();
		    my $pdbRepRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query($pdbRepQuery);
		    if ($pdbRepRef) {
			foreach (sort {$a->[0] cmp $b->[0]} @$pdbRepRef){
			    next if ($_->[0] eq $pdbIdRep && $_->[1] eq $pdbChainRep);
			    push (@altIds,    $_->[0]);
			    push (@altChains, $_->[1]);
			}
		    }
		    $new_pdb->{'altIds'}    = \@altIds;
		    $new_pdb->{'altChains'} = \@altChains;
		}
		
		# get pdb entry info
		if ($params{'get_entry_info'} && $params{'get_entry_info'} !~ /^F/i) {
		    my $pdbEntriesQuery = qq{
			SELECT pe.header, pe.ascessionDate, pe.compound, pe.source, pe.resolution, pe.experimentType
			 FROM PdbEntries pe
			 WHERE pe.pdbId = '$pdbId'
		     };
		    my $pdbEntriesRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query($pdbEntriesQuery);
		    my $class    = undef;
		    my $compound = undef;
		    my $source   = undef;
		    my $exp      = undef;
		    my $res      = 'N/A';
		    my $date     = undef;
		    if ($pdbEntriesRef) {
			$class    = $pdbEntriesRef->[0]->[0];
			$date     = $pdbEntriesRef->[0]->[1];
			$compound = $pdbEntriesRef->[0]->[2];
			$source   = $pdbEntriesRef->[0]->[3];
			$res      = $pdbEntriesRef->[0]->[4];
			$exp      = $pdbEntriesRef->[0]->[5];
		    }
		    $class =~ s!\s*/\s*! / !g;
		    if ($res =~ /^[\d\.]+$/) {
			$res = sprintf ("%4.2f", $res);
		    }
		    if ($exp =~ /NMR/i) {
			$res = 'N/A';
		    } elsif ($exp =~ /X/i) {
			$exp = 'X-RAY';
		    }

		    $new_pdb->{'class'}    = $class;
		    $new_pdb->{'compound'} = $compound;
		    $new_pdb->{'source'}   = $source;
		    $new_pdb->{'exp'}      = $exp;
		    $new_pdb->{'res'}      = $res;
		    $new_pdb->{'date'}     = $date;
		}

		push (@pdbs, $new_pdb);
	    }
	}
	$self->{pdbs_} = \@pdbs;
    }

    return $self->{pdbs_};
}

sub isMetaGene()
{
    my $self = shift;
    return ($self->locusId() >= 1000000000000) ? 'TRUE' : undef;
}
    
sub isPlasmid()
{
    my $self = shift;
    my $isPlasmid = 0;
    my $sId = $self->scaffoldId();
    my $dataR = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{SELECT isGenomic FROM Scaffold WHERE scaffoldId=$sId});
    $isPlasmid = 1 if $dataR->[0][0] == 0;
    return $isPlasmid;
}
sub bestBlastpRef()
{
    die "Deprecated";
#    my $self = shift;
#    my $excludeParalog = @_?$_[0]:0;
#    if (!defined($self->{bestBlastp_})){
#	my $locusId = $self->{locusId_};
#	my $taxId = $self->taxonomyId();
#	my $blastRef;
#	if ($excludeParalog){
#		# this line for all-in-one BLASTp table
##	    $blastRef = GenomicsUtils::query(qq{SELECT b.subject, b.score, b.identity, b.evalue, b.alignLength from BLASTp b, Locus o, Scaffold s where b.locusId=$locusId AND b.subject<>$locusId AND o.locusId=b.subject AND o.priority=1 AND s.scaffoldId=o.scaffoldId AND s.isActive=1 AND s.taxonomyId<>$taxId order by score desc limit 1;});
#		# this line for split BLASTp tables
#	    $blastRef = GenomicsUtils::query(qq{SELECT b.subject, b.score, b.identity, b.evalue, b.alignLength from `BLASTp_$taxId` b, Locus o, Scaffold s where b.locusId=$locusId AND b.subject<>$locusId AND o.locusId=b.subject AND o.priority=1 AND s.scaffoldId=o.scaffoldId AND s.isActive=1 AND s.taxonomyId<>$taxId order by score desc limit 1;});
#	    
#	}
#	else{
#		# this line for all-in-one BLASTp table
##	    $blastRef = GenomicsUtils::query(qq{SELECT b.subject, b.score, b.identity, b.evalue, b.alignLength from BLASTp b, Locus o, Scaffold s where b.locusId=$locusId AND b.subject<>$locusId AND o.locusId=b.subject AND o.priority=1 AND s.scaffoldId=o.scaffoldId AND s.isActive=1 order by score desc limit 1;})
#		# this line for split BLASTp tables
#	    $blastRef = GenomicsUtils::query(qq{SELECT b.subject, b.score, b.identity, b.evalue, b.alignLength from `BLASTp_$taxId` b, Locus o, Scaffold s where b.locusId=$locusId AND b.subject<>$locusId AND o.locusId=b.subject AND o.priority=1 AND s.scaffoldId=o.scaffoldId AND s.isActive=1 order by score desc limit 1;})
#	}
#	if (defined($blastRef->[0][0])){
#	    my $tempObj = Gene::new(locusId=>$blastRef->[0][0]);
#	    my %hitInfo = (
#			   subject => $tempObj,
#			   score => $blastRef->[0][1],
#			   identity => $blastRef->[0][2],
#			   evalue => $blastRef->[0][3],
#			   align => $blastRef->[0][4]
#			   );
#	    $self->{bestBlastp_} = \%hitInfo;
#
#	}
#
#    }
#    return $self->{bestBlastp_};
}

# in: list of genes
# out: list of scores, or 0 if there are none
sub blastScores() {
    die "Deprecated";
#    my $self = shift;
#	my $taxId = $self->taxonomyId();
#    my @genes = @_;
#    return () unless @genes;
#    # later (higher) scores will overwrite earlier (lower) scores (see map command below)
#
#
#	# this line for all-in-one BLASTp table
##    my $query = "SELECT b.subject,b.sVersion,b.score FROM BLASTp b"
#	# this line for split BLASTp tables
#    my $query = "SELECT b.subject,b.sVersion,b.score FROM `BLASTp_$taxId` b"
#	. " WHERE b.locusId=" . $self->locusId()
#	. " AND b.version=" . $self->version()
#	. " AND b.subject IN (" . join(",",map { $_->locusId(); } @genes) . ")"
#	. " ORDER BY score";
#    my $results = GenomicsUtils::query($query);
#    my %svToScore = map { $_->[0] . "," . $_->[1] => $_->[2] } @$results;
#    my @scores = map $svToScore{$_->locusId() . "," . $_->version()}, @genes;
#    return map { defined $_ ? $_ : 0 } @scores;
}

# returns taxonomyId, locusId, score, or ()
sub BestHitTaxa() {
    die "Deprecated";
#    my $self = shift;
#	my $taxId = $self->taxonomyId();
#    my @taxa = @_;
#
#	# this line for split BLASTp tables
##	. " FROM `BLASTp_$taxId` b, Locus l, Scaffold s"
#	# this as second line for all-in-one BLASTp table
##	. " FROM BLASTp b, Locus l, Scaffold s"
#
#    my $query = "SELECT s.taxonomyId,b.subject,b.score,b.identity,b.evalue"
#	. " FROM `BLASTp_$taxId` b, Locus l, Scaffold s"
#	. " WHERE b.locusId=" . $self->locusId()
#	. " AND b.version=" . $self->version()
#	. " AND b.subject <> b.locusId"
#	. " AND b.subject=l.locusId AND b.sVersion=l.version AND l.priority=1"
#	. " AND l.scaffoldId=s.scaffoldId AND s.isActive=1"
#	. " AND s.taxonomyId IN (" . join(",",@taxa) . ")"
#	. " ORDER BY b.score DESC LIMIT 1";
#    my $results = GenomicsUtils::query($query);
#    return() if (@$results == 0);
#    return @{$results->[0]};
}

#sub getDescription($)
#{
#    my $locus = shift;
#    my $annotations = GenomicsUtils::query( qq{SELECT descriptionId, description, created, source, locusId, version from Description WHERE locusId='$locus' } );

#    my @annotations;
#    foreach my $refRow (@$annotations) {
#	my ($descriptionId, $description, $created, $source, $locusId, $version ) = @$refRow;
#	push @annotations, Description::new( $descriptionId, $description, $created, $source, $locusId, $version );
#    }

#    return \@annotations;
#}

sub getOrthologList($){
    return @{&getOrthologListRef(@_)};
}

sub orthologs($){
	my $self = shift;
	my @orthologs = keys %{ $self->treeOrthologs() };
	return @orthologs;

}
sub getOrthologListRef($){
    my $self = shift;
    if (!exists $self->{orthologListRef_}) {
	my @orthologs = $self->orthologs();
	if (scalar @orthologs) {
	    $self->{orthologListRef_} = Bio::KBase::ProteinInfoService::Scaffold::fetchGenesListRef( locusId => \@orthologs);
	} else {
	    $self->{orthologListRef_} = [];
	}
    }
    return $self->{orthologListRef_};
}

sub getOrtholog($$){
    my ($self, $taxonomyId) = @_;
    my $orthList = $self->getOrthologListRef();

    foreach my $orth (@$orthList){
	return $orth if $orth->scaffold()->taxonomyId() == $taxonomyId;
    }

    return undef;
}

# arguments: a list of locusIds, and a list of taxonomyIds to fetch orthologs in
# If $taxa is undef, then it sets it to all 
# result: a hash of locusId => taxonomyId => mogOrthologId
sub MOGForTaxa {
    my ($loci,$taxa) = @_;
    return {} if @$loci == 0;
    return {} if defined($taxa) && @$taxa == 0;
    my $lociSpec = join(",",@$loci);
    my $taxWhere = defined $taxa ?
	"OR m2.taxonomyId IN (" . join(",",@$taxa) . ")"
	: "";
    my $results = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{ SELECT m1.locusId,m2.locusId,
					   m1.mogId, m2.treeId, m2.ogId, m2.taxonomyId
					       FROM MOGMember m1 JOIN MOGMember m2 USING (mogId)
					       WHERE m1.locusId IN ($lociSpec)
					       AND (m1.taxonomyId=m2.taxonomyId $taxWhere) });
    my %locusTax = ();
    my %locusTree = ();
    my %locusOg = ();
    my %locusMog = ();
    my %mogTaxMember = (); # mog => taxonomyId => member
    foreach my $row (@$results) {
	my ($locus1,$locus2,$mogId,$tree2,$og2,$tax2) = @$row;
	$locusTax{$locus2} = $tax2;
	$locusTree{$locus2} = $tree2;
	$locusOg{$locus2} = $og2;
	$locusMog{$locus2} = $mogId;
	push @{ $mogTaxMember{$mogId}{$tax2} }, $locus2;
    }
    my %out = ();
    foreach my $locusId (@$loci) {
	next unless exists $locusMog{$locusId};
	die unless exists $locusTax{$locusId};
	my $taxId = $locusTax{$locusId};
	my $mogId = $locusMog{$locusId};
	my $treeId = $locusTree{$locusId};
	my $ogId = $locusOg{$locusId};
	my @thisTaxMembers = @{ $mogTaxMember{$mogId}{$taxId} };

	# Note, even if not 1:1 we could still look for narrower og-groups
	if (@thisTaxMembers == 1) {
	    while (my ($tax2, $members) = each %{ $mogTaxMember{$mogId} }) {
		next if $tax2 == $taxId;
		if (@$members == 1) {
		    $out{$locusId}{$tax2} = $members->[0];
		} else {
		    my @matched = grep {$locusTree{$_} == $treeId && $locusOg{$_} == $ogId} @$members;
		    $out{$locusId}{$tax2} = $matched[0] if @matched == 1;
		}
	    }
	}
    }
    return \%out;
}

sub scaffold()
{
    my $self = shift;
    if( !defined($self->{scaffold_}) ) {
	my $locusId = $self->locusId();
	my $version = $self->{version_};
	my $scaffoldId = Bio::KBase::ProteinInfoService::GenomicsUtils::dbh()->selectrow_array( qq/SELECT scaffoldId 
from Locus where locusId=$locusId and version=$version/ );
	$self->{scaffold_} = Bio::KBase::ProteinInfoService::Scaffold::new( scaffoldId => $scaffoldId );
	print STDERR "Bio::KBase::ProteinInfoService::Gene.pm: get scaffoldId for a single locus\n"
	    if Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() >= 10;
    }
    return $self->{scaffold_};
}

sub scaffoldId() {
    my $self = shift;
    return $self->scaffold()->scaffoldId();
}
sub scaffoldInfo() {
    my $self = shift;
    return $self->scaffold()->comment();
}
sub taxonomyId(){
    my $self = shift;
    return $self->scaffold()->taxonomyId();
}
sub taxonomyName(){
    my $self = shift;
    return $self->scaffold()->taxonomyName();
}
sub taxonomyShort(){
    my $self = shift;
    return $self->scaffold()->taxonomyShort();
}

sub type() { my $self = shift; return $self->{type_}; }
sub isPseudo() { my $self = shift; return $self->{type_} == 7 || $self->{type_} == 8; }
sub isProtein() {  my $self = shift; return $self->{type_} == 1; }
sub istRNA() {  my $self = shift; return $self->{type_} == 5; }
sub isrRNA() {  my $self = shift; return $self->{type_} >= 2 && $self->{type_} <= 4; }

sub index()
{
    my $self = shift;
    if( !defined($self->{index_}) ) {
	my $locusId = $self->locusId();
	my $g = $self->scaffold()->genesMapRef()->{$locusId};
	die "Logic error in Gene::index()\n" unless defined( $g->{index_} );
# 	my $genes = $self->scaffold()->genesRef();

# 	my $index = 0;
# 	foreach my $g (@$genes) {
# 	    last if ( $g->locusId()==$locusId );
# 	    ++$index;
# 	}
	$self->{index_} = $g->{index_};
    }
    return $self->{index_};
}

sub setIndex($){
    my $self = shift;
    $self->{index_} = $_[0];
}

sub indexAssigned()
{
    my $self = shift;
    return defined($self->{index_});
}

sub upstreamGene(){
    my $self = shift;
    my $g = ( $self->{strand_} eq '+') ? $self->previousGene() :
	$self->nextGene();

    return undef unless defined $g;
    return ($self->{strand_} eq $g->strand()) ? $g : undef;
}

sub downstreamGene(){
    my $self = shift;
    my $g = ( $self->{strand_} eq '+') ? $self->nextGene() :
	$self->previousGene();

    return undef unless defined $g;
    return ($self->{strand_} eq $g->strand()) ? $g : undef;
}

sub nextGene(){
    my $self = shift;
    if (! $self->scaffold()->hasLoadedGenes() && $self->begin() < $self->end())
	{
		# try to compute them incrementally from list of genes within 10 kB
		my @list = $self->scaffold()->genesWithin($self->begin(), $self->end() + 15000);
		my @selfI = grep { $list[$_]->locusId() == $self->locusId() } (0..(scalar(@list)-1));
		warn "no previous gene, doing the slow way" unless @selfI == 1;
		my $selfI = $selfI[0];
		if ($selfI < scalar(@list)-1) {
		    return $list[$selfI+1];
		}
    }

    # else do it the slow way
    my $index = $self->index();
    my $genes = $self->scaffold()->genesRef();
    if( $index<@$genes-1 ) {
		return $genes->[$index+1];
    } 
    if ( $self->scaffold()->isCircular() && !$self->scaffold()->isPartial() )
	{
		return $genes->[0];
    }
    return undef;
}

sub previousGene(){
    my $self = shift;

    if (! $self->scaffold()->hasLoadedGenes() && $self->begin() < $self->end())
	{
		my @list = $self->scaffold()->genesWithin(
			$self->begin() - 15000, $self->end());
		my @selfI = grep { $list[$_]->locusId() == $self->locusId() }
			(0..(scalar(@list)-1));
		warn "no previous gene, doing the slow way" unless @selfI == 1;
		my $selfI = $selfI[0];
		if ($selfI > 0) {
		    return $list[$selfI-1];
		}
    }

    # else do it the slow way

    my $index = $self->index();
    my $genes = $self->scaffold()->genesRef();
    if( $index>0 ) {
	my $gene = $$genes[$index - 1];
	return $gene;
    } 
    if ( $self->scaffold()->isCircular() &&
	 !$self->scaffold()->isPartial() ){
	return $genes->[@$genes-1];
    }	
    return undef;
}

sub getUpstream{
    my $self = shift;
    my %params = @_;
    my $downstream = defined($params{'downstream'}) &&                        
	$params{'downstream'};

    #how many bps?
    my $length = defined($params{'length'}) ?
	$params{'length'} : 150;
    #how far upstream? 0 stops before the first base of the start codon
    my $offset = defined($params{'offset'}) ?
	$params{'offset'} : 0;
    # from of 1 means start codon; 0 means the base before the start codon
    # (not -1 as biologists usually use)
    my $fromOff = defined $params{'from'} ? $params{'from'} : undef;


    my $plusStrand = ($self->{'strand_'} eq '+');
    #if "downstream" is passed in, treat this like the upstream of the
    #antisense strand (but we won't reverseComplement later)
    $plusStrand = !$plusStrand if $downstream;

    my ($begin,$end); # always try to have $begin<$end (except for wrap) and deal with reversing later
    if (defined $fromOff) {
	if ($plusStrand) {
	    $begin = $self->begin + ($fromOff-1);
	    $end = $begin + ($length-1);
	} else {
	    $end = $self->end - ($fromOff-1);
	    $begin = $end - ($length-1);
	}
    } else {
	$begin = $plusStrand ? $self->begin - $length - $offset : $self->end + $offset + 1;
	$end = $begin + $length - 1;
    }

    #truncate regions overlapped by other Locuses

    #OK - this ignores the possibility of a gene further
    #(up/down)stream that also overlaps our gene start
    #I don't know if this actually happens, but imagine it
    #could esp. for lousy gene models
    if (defined $params{'truncate'} && $params{'truncate'}){
	my $upGene;
	if ($plusStrand && ($upGene = $self->previousGene)){
	    $begin = ($begin < $upGene->end() + 1) ?
		$upGene->end() + 1 : $begin;
	}elsif ($upGene = $self->nextGene()){
	    $end = ($end > $upGene->begin() - 1) ?
		$upGene->begin() - 1 : $end;
	}
    }
    if ($begin < 1 && !($self->scaffold->isCircular && !$self->scaffold->isPartial)) {
	$begin = 1;
    }
    if ($end > $self->scaffold->length && !($self->scaffold->isCircular && !$self->scaffold->isPartial)) {
	$end = $self->scaffold->length;
    }

    return "" if $end < $begin;

    my $seq = $self->scaffold()->subsequence($begin, $end, 1); # 1 means try to wrap if appropriate
    return &Bio::KBase::ProteinInfoService::GenomicsUtils::reverseComplement( $seq ) if ( (!$plusStrand && !$downstream) ||
							  ($plusStrand && $downstream) );
    return $seq;
}

sub setSynonym($) 
{
    my $self = shift;
    my $synRef = shift;

    $self->{synonym_} = $synRef;
}

#REMOVED - setScaffold not needed b/c scaffold is preloaded (see Scaffold:new())
#sub setScaffold($) 
#{
#    my $self = shift;
#    my $scaffoldRef = shift;
#
#    $self->{scaffold_} = $scaffoldRef;
#}

sub evidence() {
    my $self = shift;
    return &Bio::KBase::ProteinInfoService::GenomicsUtils::queryScalar("SELECT evidence from Locus where locusId=" . $self->locusId()
				       . " AND version=" . $self->version() );
}

sub getBlastPHitsRef(){ # fast-blast
    my $self = shift;
	my %args = @_;
	my $useCache = $args{useCache} || 0;
    my $locusId = $self->{locusId_};
    my $version = $self->{version_};
	my $taxId = $self->taxonomyId();

    return $self->{blastp_} if defined $self->{blastp_};
    return [] if $self->{type_} != 1;

    my $hitsFile = undef;
    my $basedir = "/tmp/fastblast.$$.";
    my $hitsFileFinal = undef; # rename hitsFile to hitsFileFinal to avoid risk of reading incomplete file
    my $hitsFileRunning = undef;
    my $cached = 0;

    # only cache if on web site
    if (exists $ENV{REQUEST_METHOD} or $useCache ) {
		$basedir = "$ENV{SANDBOX_DIR}/Genomics/html/tmp/fastblast/";
		die "fastblast subdirectory $basedir does not exist" unless -d $basedir;
		$hitsFile = "$basedir${locusId}_$version.pid$$.hits";
		$hitsFileFinal = "$basedir${locusId}_$version.hits";
		$cached = 1 if -e $hitsFileFinal;
		unless (-e $hitsFileFinal) {
			$hitsFileRunning=$hitsFileFinal.'.running';
			return undef if (-e $hitsFileRunning);
			open EMPTYFILE, '>', $hitsFileRunning and close EMPTYFILE
				or die "couldn't touch $hitsFileRunning: $!";
		}
    } else {
		$hitsFile = "$basedir${locusId}_$version.hits";
    }

    my $homeDir = $ENV{SANDBOX_DIR} || $ENV{HOME};
    die "Cannot find executables directory $homeDir/Genomics/browser/bin: $!"
		unless -d "$homeDir/Genomics/browser/bin";

    if (! $cached) {
		my $start = [ Time::HiRes::gettimeofday( ) ];
		my $debug = Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug();

		my @maybeHits = ();
		my $tmpPre = "/tmp/fastblast$$.";

		### completely new for fasthmm version of FastBLAST
		# todo:
		# put options into Browser::Defaults?
		my $fastBLASTDir=$defaults->{FastBLASTDataDir};
		# get people to set up ~/fasthmm
		my $fbOptions = FastBLAST::Options();
		$fbOptions->{debug} = 1 if $debug > 1;
		InitDomains($fastBLASTDir);
		my $dbSize = FetchNSequences($fastBLASTDir);
		my $nTopHits = int($dbSize/$fbOptions->{nthTopHits});
		$nTopHits = 10 if $nTopHits < 10;

		$ENV{FASTHMM_DIR}="$ENV{SANDBOX_DIR}/fasthmm";
		FastBLAST("${locusId}_$version",$defaults->{FastBLASTInputFile},$nTopHits,$hitsFile);

		# next, do proteinBlatSearch if needed
		my $crc=$self->crc64;
		my $seq=$self->protein;
		my $shortSeqAA=25;
		my $tmpDir = $defaults->{'htmlTmpDir'} . "fastblast";
		my $tmpUri = $defaults->{'htmlTmpUri'} . "fastblast";
		my $fastaUri = "$tmpUri/$crc.fasta";
		my $fastaFile = "$tmpDir/$crc.fasta";
		# Ignore possibility of 64-bit collisions, or time-racing b/w two processes
		if (! -e $fastaFile) {
			open(FAA,">",$fastaFile) || die "Cannot write to $fastaFile";
			print FAA Bio::KBase::ProteinInfoService::GenomicsUtils::formatFASTA($crc,$seq);
                        close(FAA) || die "Error writing to $fastaFile";
		}

		# the 1 suppresses normal output from proteinBlatSearch
		# the showMeta test is completely untested in the isolate site
		my ($blathits,$bblasthits,$blatUri,$blastUri2)=Bio::KBase::ProteinInfoService::GenomicsUtils::proteinBlatSearch($fastaFile,$fastaUri,$debug,$seq,$shortSeqAA,1) unless ($defaults->{showMeta} == 1);

		if (defined $hitsFileFinal) {
			# need to combine BLAT results with FastBLAST
		    # the perl one-liner is completely idiotic,
		    # but just want to get it working
		    (system("cut -f2-  $hitsFile | perl -pi -e 's/lcl.([0-9]+)_[0-9]+/lcl\|VIMSS\$1/;' > $hitsFile.cut") == 0 && -e "$hitsFile.cut")
			|| die "Cannot create $hitsFile.cut: $!";
		    if (-e "$fastaFile.psl.blastp")
		    {	
			    (system("cut -f2-  $fastaFile.psl.blastp > $fastaFile.psl.blastp.pid$$.cut") == 0 && -e "$fastaFile.psl.blastp.pid$$.cut")
				|| die "Cannot create $fastaFile.psl.blastp.pid$$.cut: $!";
		    } else
		    {
				system("touch $fastaFile.psl.blastp.pid$$.cut")==0
				|| die "Cannot create $fastaFile.psl.blastp.pid$$.cut: $!";
		    }
		    (system("sort -u $hitsFile.cut $fastaFile.psl.blastp.pid$$.cut > $hitsFile.cut.combined.sorted") == 0 && -e "$hitsFile.cut.combined.sorted")
			|| die "Cannot create $hitsFile.cut.combined.sorted: $!";
		    (system("sort -n -k11 -r $hitsFile.cut.combined.sorted > $hitsFileFinal") == 0 && -e $hitsFileFinal)
			|| die "Cannot create $hitsFileFinal: $!";
		    my $numFiles=unlink <$tmpDir/*.pid$$.*> or die "Couldn't remove *.pid$$.*: $!";
#		    (system("mv $hitsFile $hitsFileFinal") == 0 && -e $hitsFileFinal)
#			|| die "Cannot create $hitsFileFinal: $!";
		} else {
		    $hitsFileFinal = $hitsFile;
		}
	}

    unlink $hitsFileRunning if ($hitsFileRunning and -e $hitsFileRunning);
   
    # read hits from hitsFile
    my $hits = [];
    open(HITS, "<", $hitsFileFinal) || die "Cannot read $hitsFileFinal: $!";
    while(<HITS>) {
	chomp;
	my @F = split /\t/, $_;
	my ($subj, $identity, $alignLength, $mismatch, $gap,
	    $qBeg, $qEnd, $sBeg, $sEnd, $eval, $score) = @F;
#	my ($qry, $subj, $identity, $alignLength, $mismatch, $gap,
#	    $qBeg, $qEnd, $sBeg, $sEnd, $eval, $score) = @F;
	die "Error parsing $hitsFileFinal: $_" unless defined $score;
#	my ($query)=$qry=~/^lcl\|(\d+)_\d+$/;
	my $query=$self->locusId;
#	my ($subject,$sVersion)=$subj=~/^lcl\|(\d+)_(\d+)$/;
	my ($subject)=$subj=~/^lcl\|VIMSS(\d+)$/;
#	$subject =~ s/^lcl[|]//;
#	$subject =~ s/^VIMSS//;
	push @$hits, {query => $query,
		      subject => $subject,
#		      sVersion => $sVersion,
		      identity => $identity,
		      alignLength => $alignLength,
		      mismatch => $mismatch,
		      gap => $gap,
		      qBegin => $qBeg,
		      qEnd => $qEnd,
		      sBegin => $sBeg,
		      sEnd => $sEnd,
		      evalue => $eval,
		      score => $score};
    }
    close(HITS) || die "Error reading $hitsFileFinal";
    unlink($hitsFileFinal) if $hitsFile eq $hitsFileFinal;
    $self->{blastp_} = $hits;
    return $self->{blastp_};
}

sub getSubjectBlastPList(){
    die "Deprecated";
#    return @{&getSubjectBlastPListRef(@_)};
}

sub getSubjectBlastPListRef(){
    die "Deprecated";
#    my $self = shift;
#    my $locusId = $self->{locusId_};
#    my $version = $self->{version_};
#	my $taxId = $self->taxonomyId();
#
#    #add taxId here in query    
#
#	# this line for all-in-one BLASTp table
##    my $statement = qq(select * from BlastP where subject=$locusId and version=$version);
#	# this line for split BLASTp tables
#    my $statement = qq(select * from `BLASTp_$taxId` b where subject=$locusId and version=$version);
#
#    my $sth = GenomicsUtils::dbh()->prepare($statement);
#    $sth->execute();
#    my @resultSet;
#    while( my $row_hash = $sth->fetchrow_hashref() ) {
#	push @resultSet, $row_hash; 
#    }
#    $sth->finish;
#    return \@resultSet;
}

sub getBestHitList{
    die "No longer supported";
}

sub getBestHitListRef{
    die "No longer supported";
}

sub getOperon{
    my $self = shift;
    my %params = @_;
    my %locusMap;
    my $locusId = $self->locusId();

    #make a hash of all genes in an operon w/ query
    my @locusIds = Bio::KBase::ProteinInfoService::GenomicsUtils::queryList( qq{ SELECT o2.locusId FROM Locus2Operon o1, Locus2Operon o2
						     WHERE o1.locusId=$locusId AND o1.tuId=o2.tuId
						     GROUP BY o2.locusId } );
    if (scalar @locusIds == 0) { return(); }
    my %genes = &Bio::KBase::ProteinInfoService::Scaffold::fetchGenesMap( locusId => [@locusIds] );

    #return a hash of operons indexed by tuId
    if ((defined $params{map}) && $params{map}){

	#get key,value pairs
	my @TUs = @{Bio::KBase::ProteinInfoService::GenomicsUtils::query( qq{ SELECT o2.tuId, o2.locusId FROM Locus2Operon o1, Locus2Operon o2, Position p, Locus o WHERE o1.locusId=$locusId AND o1.tuId=o2.tuId AND o2.locusId=o.locusId AND o.posId=p.posId ORDER BY p.begin} )};
	#sort by most upstream
	@TUs = reverse @TUs if $self->strand() eq '-';
	my @locusMap = map {@$_} @TUs;
	my $key;
	my $isKey = 0;

	#make hash using genes already retrieved from DB
	foreach my $val (@locusMap){
	    $isKey = !$isKey;
	    if ($isKey){
		$key = $val;
		next;
	    }
	    push @{$locusMap{$key}}, $genes{$val};
	}
	return %locusMap;
    }

    #sort by most upstream
    my @genes = sort {$a->start() <=> $b->start()} values %genes;
    if ($self->strand() eq '-'){
	return reverse @genes;
    }
    return @genes;
}

sub gff{
    my $self = shift;
    my @features = ( "VIMSS".$self->locusId(), #seqname
		     "VIMSS_DB", #source
		     "gene model", #feature
		     $self->begin(), #start (must be <= end)
		     $self->end(), #end
		     ".", #score
		     $self->strand(), #strand
		     ".", #frame
		     join ";", map { "Synonym$_ "."\"".${$self->synonym()}{$_}."\"" }
		     sort keys %{$self->synonym()} ); #attribute


   return join "\t", @features;
}

sub regulon{
    my $self = shift;
    
    unless (defined($self->{regulon_})){
	my $locusId = $self->locusId();
	my $sql = qq{
	    SELECT clusterId
	    FROM RegulonCluster
	    WHERE locusId=$locusId
	};
	my $queryR = Bio::KBase::ProteinInfoService::GenomicsUtils::query($sql);
	return undef if !defined($queryR->[0][0]);
	$self->{regulon_} = Bio::KBase::ProteinInfoService::Regulon::new(clusterId=>$queryR->[0][0]);

    }
    return $self->{regulon_};
}

sub operonId{
    my $self = shift;
    unless (defined($self->{operonId_})){
	my $locusId = $self->locusId();
	my $sql = qq{
	    SELECT tuId
	    FROM Locus2Operon
	    WHERE locusId=$locusId
	};
	my $queryR = Bio::KBase::ProteinInfoService::GenomicsUtils::query($sql);
	return undef if !defined($queryR->[0][0]);
	$self->{operonId_} = $queryR->[0][0];
    }
    return $self->{operonId_};
}

# Note -- there is now a Locus2SwissProt table (a 1->many relationship, with only the best hit(s),
# and with a flag indicating if it is a bidirectional-best-hit), which is used by the website instead
sub uniprot{
	my $self = shift;
	my $locusId = $self->locusId();
	my $version = $self->version();
	my $sql = qq{
	   SELECT uniprot
	   FROM Locus2Checksum
	   WHERE locusId=$locusId
	   AND version=$version
	};
	my $queryR = Bio::KBase::ProteinInfoService::GenomicsUtils::query($sql);
	return undef if !defined($queryR->[0][0]);
	return $queryR->[0][0];

}

sub maData{
	# this sub can take a Gene object or a locusId
    my $self = shift;
    my $locusId;

    if (ref $self)
    {
	$locusId = $self->locusId();
    } else {
	$locusId = $self;
    }

    my $sql = qq{
	SELECT count(*)
	FROM microarray.MeanLogRatio m inner join microarray.Exp e on e.id = m.expId
	WHERE m.locusId=$locusId
	and e.expType='RNA'};
    my $queryR = Bio::KBase::ProteinInfoService::GenomicsUtils::query($sql);
    #print STDERR $sql;
    return undef if !defined($queryR->[0][0]);
    return $queryR->[0][0];
}

sub fitnessData
{
	# this sub can take a Gene object or a locusId
    my $self = shift;
    my $locusId;

    if (ref $self)
    {
		$locusId = $self->locusId();
    } else {
		$locusId = $self;
    }

    my $sql = qq{
	SELECT count(*)
	FROM microarray.MeanLogRatio m inner join microarray.Exp e on e.id = m.expId
	WHERE m.locusId=$locusId
	and e.expType='Fitness'};
    my $queryR = Bio::KBase::ProteinInfoService::GenomicsUtils::query($sql);
    #print STDERR $sql;
    return undef if !defined($queryR->[0][0]);
    return $queryR->[0][0];
}


sub expIds {

my $self=shift;
my $genome=Bio::KBase::ProteinInfoService::Genome::new(taxonomyId=>$self->taxonomyId);
return $genome->expIds(@_);

}

sub LocusPapers($) {
    my ($locusId) = @_;
    my @papers1 = &Bio::KBase::ProteinInfoService::GenomicsUtils::queryList(qq{SELECT DISTINCT p.PubMedId
						   FROM SwissProt2Locus l JOIN SwissProt2Pubmed p USING (accession)
						   WHERE l.locusId=$locusId AND p.isDetailed=1});
    my @papers2 = &Bio::KBase::ProteinInfoService::GenomicsUtils::queryList(qq{SELECT DISTINCT pubMedId FROM Locus2RTBArticles
						   WHERE locusId=$locusId});
    my %papers = ();
    foreach (@papers1) { $papers{$_} = 1; }
    foreach (@papers2) { $papers{$_} = 1; }
    return sort {$a<=>$b} keys(%papers);
}

sub papers($) {
    my $self = shift;
    if (exists $self->{papers_}) {
	return @{ $self->{papers_} };
    }
    #else
    my @papers = LocusPapers($self->{locusId_});
    $self->{papers_} = \@papers;
    return @papers;
}

# Given a reference to list of locusIds, and a bidir flag,
# return the subset that are characterized (as a list)
# Use the bidir flag set to 1 if selecting characterized homologs from a list --
# otherwise all members of a species will be labelled.
sub characterizedSubset($$) {
    my ($locusIds,$bidir) = @_;
    return () if @$locusIds==0;
    my $locusSpec = join(",",@$locusIds);
    my $table = $bidir ? "SwissProt2Locus" : "Locus2SwissProt";
    my @sub1 = Bio::KBase::ProteinInfoService::GenomicsUtils::queryList(qq{SELECT DISTINCT l.locusId 
					       FROM $table l JOIN SwissProt2Pubmed p USING (accession)
					       WHERE p.isDetailed=1 AND l.locusId IN ($locusSpec) });
    my @sub2 = Bio::KBase::ProteinInfoService::GenomicsUtils::queryList(qq{SELECT DISTINCT locusId FROM Locus2RTBArticles
					       WHERE locusId IN ($locusSpec)});
    my %sub = map {$_ => 1} @sub1;
    foreach (@sub2) { $sub{$_} = 1; }
    return sort keys %sub;
}


# Given a reference to list of locusIds
# return the subset that have PDB structures (as a list)
sub pdbStructuresSubset($) {
    my ($locusIds) = @_;
    return () if @$locusIds==0;
    my $locusSpec = join(",",@$locusIds);
    my $table = "Locus2Pdb";
    my @sub1 = Bio::KBase::ProteinInfoService::GenomicsUtils::queryList(qq{SELECT DISTINCT l.locusId 
					       FROM $table l
					       WHERE l.identity >= 97 AND l.locusId IN ($locusSpec) });
    my %sub = map {$_ => 1} @sub1;
    return sort keys %sub;
}

sub geneTreeRows {
    my $self = shift;
    my $locusId = $self->locusId();
    my $version = $self->version();
    return( Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{SELECT t.treeId,t.name,t.type,l2t.begin,l2t.end,l2t.aaTree,l2t.nAligned,l2t.score
				       FROM Tree t, Locus2Tree l2t
				       WHERE t.treeId=l2t.treeId AND l2t.locusId=$locusId AND l2t.version=$version
				       ORDER BY t.name, l2t.begin}) );
}

# argument is the result from geneTreeRows()
sub selectGeneTreeRow($) {
    my $self = shift;
    my $treeRows = shift;
    my $locusId = $self->locusId();
    my ($ID,$NAME,$TYPE,$BEGIN,$END,$AA,$NALIGN,$SCORE) = (0..7);

    return undef if @$treeRows == 0;

    # First, select a few candidates, including ad hoc and FastBLAST trees,
    # but only the top couple as measured by nAligned
    my @topFam = grep {$_->[$TYPE] ne "FastBLAST" && $_->[$TYPE] ne "Adhoc"} @$treeRows;
    my @topBLAST = grep {$_->[$TYPE] eq "FastBLAST"} @$treeRows;
    my @topAdHoc = grep {$_->[$TYPE] eq "Adhoc"} @$treeRows;

    @topFam = sort {$b->[$NALIGN] <=> $a->[$NALIGN]} @topFam;
    $#topFam = 1 if scalar(@topFam)>2;

    @topBLAST = sort {$b->[$NALIGN] <=> $a->[$NALIGN]} @topBLAST;
    $#topBLAST = 1 if scalar(@topBLAST)>2;

    @topAdHoc = sort {$b->[$NALIGN] <=> $a->[$NALIGN]} @topAdHoc;
    $#topAdHoc = 1 if scalar(@topAdHoc)>2;

    my @top = ();
    push @top, @topFam;
    push @top, @topBLAST;
    push @top, @topAdHoc;

    my $nOrthBest = 0;
    my $treeRow = undef;

    # Now, compute the number of orthologs retained by each
    my @orthologs = $self->orthologs();
    return $top[0] if @orthologs == 0;
    my $orthSpec = join(",", @orthologs);
    foreach my $row (@top) {
	my $nOrth = Bio::KBase::ProteinInfoService::GenomicsUtils::queryScalar(qq{ SELECT count(DISTINCT locusId)
						       FROM Locus2Tree
						       WHERE treeId = $row->[$ID]
						       AND locusId IN ($orthSpec) });
	print STDERR "nOrth in tree $nOrth for tree $row->[$ID] $row->[$TYPE] $row->[$NAME]\n"
	    if Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() > 1;
	if ($nOrth > $nOrthBest || !defined $treeRow) {
	    $treeRow = $row;
	    $nOrthBest = $nOrth;
	}
    }
    return $treeRow;
}

# Select the tree rows to use to predict orthologs
#
# First, we select the best trees to use
# by selecting the best FastBLAST domains and their corresponding trees
# Then, if we don't have enough trees (e.g., there is no tree for
# some of those domains), add a couple more trees with high nAlign
# Finally, sort the trees by how "good" they are, using nAlign
#
# The map between trees and FastBLAST domains is not straightforward:
# PANTHER domains have names like PTHR21123 but no trees
# PFam fragment hits (*.fs) have no trees
# Futhermore, the naming is inconsistent -- the following table gives
# examples of FastBLAST domain names and their corresponding trees:
# gnl|CDD|31604 => type=COG name=1414 #XXX we will soon have COG trees as well (just good-hits)
# PF09339.1 or PF09339.1.fs => type=PFAM name=PF09339
# 0043944 => type=SSF name=SSFmodel0043944
# fb.2489269_1.1.55 => type=FastBLAST name=FastBLAST.2489269.1.1.55
# PIRSF000443 => type = PIRSF name = PIRSF000443
# TIGR03215 => type = TIGRFAMs name = TIGR03215
# 1b4uB00 => type = GENE3D name = 1b4uB00
# HTH_ICLR => type=SMART name=SM00346
#
#
sub treesForOrthologs($$) {
    my ($self,$gooddom) = @_;
    return() if $self->type() != 1;
    my $locusId = $self->locusId();
    my $version = $self->version();

    # Sort by name and collect the corresponding trees
    my @sorteddom = sort {$b->[6] <=> $a->[6]} @$gooddom;
    my ($ID,$NAME,$TYPE,$BEGIN,$END,$AA,$NALIGN,$SCORE) = (0..7);
    print STDERR join("\t", "TryingDom",map {$_->[0]} @sorteddom)."\n"
	if Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() > 1;
    my $genetreeRows = $self->geneTreeRows();
    my %treerowsByName = (); # indexed by name_type
    foreach my $row (@$genetreeRows) {
	push @{ $treerowsByName{join("_",$row->[$TYPE],$row->[$NAME])} }, $row;
    }

    # and translate the names for COG and optionally for SMART
    my %COGsUsed = map {$_->[$NAME] => 1} grep {$_->[$TYPE] eq "COG"} @$genetreeRows; # cogInfoIds
    my $COGsUsedSpec = join(",", keys(%COGsUsed));
    my $CDDToCOG = {}; # cddId to list of one cogId, e.g. gnl|CDD|30733 => 384
    if ($COGsUsedSpec ne "") {
	$CDDToCOG = Bio::KBase::ProteinInfoService::GenomicsUtils::queryHashList(qq{ SELECT cddId, cogInfoId FROM COGInfo
							 WHERE cogInfoId IN ($COGsUsedSpec) });
    }

    my @smartRowsToRemap = grep {$_->[$TYPE] eq "SMART"} @$genetreeRows;
    my %SmartUsed = map {$_->[$NAME] => 1} @smartRowsToRemap; # domainIds
    my $SmartUsedSpec = join(",", map { qq{"$_"} } keys %SmartUsed);
    my $SmartNameToId = {}; # name to list of one id, e.g. HTH_ICLR => SM00346
    if ($SmartUsedSpec ne "") {
	$SmartNameToId = Bio::KBase::ProteinInfoService::GenomicsUtils::queryHashList(qq{ SELECT domainName, domainId FROM DomainInfo
							      WHERE domainDb="SMART" and domainId IN ($SmartUsedSpec) });
    }

    my @treesToUse = ();
    my @domSkipped = ();

    foreach my $dom (@sorteddom) {
	my ($domId,$geneId,$seqBeg,$seqEnd,$domBeg,$domEnd,$score) = @$dom;
	my $treename = "";
	if ($domId =~ m/^gnl[|]CDD/) {
	    # Ideally all good COG hits will be in trees, but in practice this might not occur
	    $treename = "COG_" . $CDDToCOG->{$domId}[0]
		if exists $CDDToCOG->{$domId};
	} elsif ($domId =~ m/^(PF\d+)[.]\d+$/) {
	    $treename = "PFAM_" . $1;
	} elsif ($domId =~ m/^PF\d+[.]\d+[.]fs/) {
	    ;
	} elsif ($domId =~ m/^\d+$/) {
	    $treename = "SSF_SSFmodel" . $domId;
	} elsif ($domId =~ m/^fb[.](\d+)_(\d+)[.](\d+)[.](\d+)$/) {
	    $treename = "FastBLAST_FastBLAST.$1.$2.$3.$4";
	} elsif ($domId =~ m/^TIGR\d+$/) {
	    $treename = "TIGRFAMs_" . $domId;
	} elsif ($domId =~ m/^PIRSF\d+$/) {
	    $treename = "PIRSF_" . $domId;
	} elsif ($domId =~ m/^PTHR\d+$/) {
	    ;
	} elsif ($domId =~ m/^\d[0-9a-z][0-9a-z][0-9a-z][0-9A-Z]\d\d$/) {
	    $treename = "GENE3D_" . $domId;
	} else {
	    # assume is a smart id
	    die "Do not recognize id $domId IN SMART"
		unless exists $SmartNameToId->{$domId};
	    $treename = "SMART_" . $SmartNameToId->{$domId}[0];
	}
	# Match tree rows by begin/end as well
	# But they don't line up for fb. domains b/c of a bug in FastBLAST
	if (exists $treerowsByName{$treename}) {
	    my @rows = @{ $treerowsByName{$treename} };
	    my @rows2 = grep {$_->[$BEGIN] == $seqBeg && $_->[$END] == $seqEnd} @rows;
	    my $row = (@rows2 == 0) ? $rows[0] : $rows2[0];
	    if (@rows2 == 0) {
		# This used to happen because of a bug in FastBLAST
		# Now it happens because of multiple hits to a domain
		print STDERR "Gene::treesForOrthologs warning: FastBLAST maps $locusId"."_"."$version $domId $seqBeg:$seqEnd tree maps $row->[$ID] $row->[$NAME] $row->[$TYPE] to $row->[$BEGIN]:$row->[$END]\n"
		    if Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() > 1;
	    }
	    push @treesToUse, $row;
	} elsif ($treename ne "") {
	    # Occasionally there is no fastblast tree even though there is a genuine tree
	    # I'm not sure why...
	    print STDERR "Gene::treesForOrthologs warning: no tree for id $domId tree $treename\n";
	} else {
	    push @domSkipped, $domId;
	}
    }
    print STDERR join("\t", "Gene::treesForOrthologs", "Skipped", @domSkipped)."\n"
	if Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() > 1 && @domSkipped > 0;

    # Instead of trying to replace the skipped pfam fragments or skipped panther trees
    # with ad-hoc trees that some how correspond, just see how many trees we have
    # If we have < 2 trees, try to add more
    if (scalar(@treesToUse) < 2) {
	my %treenameUsed = map { $_->[$TYPE] . "_" . $_->[$NAME]  => 1 }  @treesToUse;
	my @rowsToUse = grep {!exists $treenameUsed{$_->[$TYPE] . "_" . $_->[$NAME]}} @$genetreeRows;
	@rowsToUse = sort { $b->[$NALIGN] <=> $a->[$NALIGN] } @rowsToUse;
	while (scalar(@treesToUse) < 2 && @rowsToUse > 0) {
	    print STDERR "Adding extra row: " . join(" ", @{$rowsToUse[0]}) . "\n"
		if Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() > 1;
	    push @treesToUse, shift @rowsToUse;
	}
    }
    if (Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() > 1) {
	if (@treesToUse > 0) {
	    print STDERR "Chose " . scalar(@treesToUse) . " trees for $locusId: "
		. join(" ", map {$_->[$TYPE] . "_" . $_->[$NAME]} @treesToUse)
		. "\n";
	} else {
	    print STDERR "Warning! No trees for $locusId\n";
	}
    }
    return @treesToUse;
}

# Given a gene object and a tree row, find the orthologs for that gene, and
# the known non-orthologs for that gene
#
# The analysis is written into the $orth argument, which is a hash of
# locusId => orthInfo, where orthInfo is a hash with the fields
#	locusId, version, isOrth, isDup, taxonomyId, aaLength,
#	treeId, ourBegin, ourEnd, minOurBegin, maxOurEnd, treeType, treeName,
#       begin, end, minBegin, maxEnd, ogId, nGenes, nGenomes, nMemberThisGenome
# isOrth if 1 if a tree-ortholog or 0 if this is a known not-ortholog
# isDup is a property of the og not of the gene
# allTruncated is 1 if nAligned is much smaller (50% less) than in the anchor gene
#	If we get a new non-truncated gene, we reset begin/end
#
# Already known genes are only updated with minBegin and maxEnd,
# which help to track the range of the gene that is potentially orthologous
#
# The $taxFound hash is to keep track of taxa that already have known orthologs
# (only counting genes with isOrth=1!)
#
sub pertreeOrthologs($$$$$) {
    my ($self,$treeRow,$orth,$taxWithOrth,$taxlist) = @_;
    my $locusId = $self->locusId();
    my $version = $self->version();
    my $ourTax = $self->taxonomyId();
    my ($ID,$NAME,$TYPE,$BEGIN,$END,$AA,$NALIGN,$SCORE) = (0..7);
    my $treeId = $treeRow->[$ID];
    my $ourBeg = $treeRow->[$BEGIN];
    my $ourEnd = $treeRow->[$END];

    # Sort by nGenes to smallest (children) ogs first
    my $query = qq{SELECT OrthologGroup.ogId, parentOg, isDuplication,
		   nGenes, nGenomes, nNonUniqueGenomes,
		   og2.locusId, og2.version,
		   og2.begin, og2.end, og2.taxonomyId,
		   og1.nMemberThisGenome, og2.nMemberThisGenome,
		   og2.aaLength,og2.nAligned
		       FROM OGMember og1
		       JOIN OrthologGroup USING (treeId,ogId)
		       JOIN OGMember og2 USING (treeId,ogId)
		       WHERE og1.treeId=$treeId
		       AND og1.locusId=$locusId AND og1.version=$version
		       AND og1.begin=$ourBeg AND og1.end=$ourEnd };

    if (defined $taxlist && @$taxlist > 0) {
	my $taxspec = join(",",@$taxlist);
	$query .= " AND og2.taxonomyId IN ($taxspec)";
    }
    my $OGMembers = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{$query ORDER BY nGenes});

    foreach my $row (@$OGMembers) {
	my ($ogId, $parentOg, $isDup,
	    $nGenes, $nGenomes, $nNonUniqueGenomes,
	    $orthId, $orthVersion, $orthBeg, $orthEnd, $orthTax,
	    $ourNThisGenome, $orthNThisGenome, $orthLen, $nAligned)
	    = @$row;
	next if $orthId eq $locusId;
	my $truncated = $nAligned < 0.5 * $treeRow->[$NALIGN] ? 1 : 0;
	if (exists $orth->{$orthId}) {
	    $orth->{$orthId}{minBegin} = $orthBeg if $orthBeg < $orth->{$orthId}{minBegin};
	    $orth->{$orthId}{maxEnd} = $orthEnd if $orthEnd > $orth->{$orthId}{maxEnd};
	    if (!$truncated && $orth->{$orthId}{allTruncated}) {
		$orth->{$orthId}{minOurBegin} = $ourBeg;
		$orth->{$orthId}{maxOurEnd} = $ourEnd;
		$orth->{$orthId}{allTruncated} = 0;
	    } elsif (!$truncated) {
		$orth->{$orthId}{minOurBegin} = $ourBeg if $ourBeg < $orth->{$orthId}{minOurBegin};
		$orth->{$orthId}{maxOurEnd} = $ourEnd if $ourEnd > $orth->{$orthId}{maxOurEnd};
	    }
	} else {
	    my $isOrth = $ourNThisGenome == 1 && $orthNThisGenome == 1 && $isDup == 0
			 && $orthTax != $ourTax && !exists $taxWithOrth->{$orthTax};
	    $taxWithOrth->{$orthTax} = 1 if $isOrth;
	    $orth->{$orthId} = { locusId => $orthId, version => $orthVersion,
				 isOrth => $isOrth ? 1 : 0,
				 isDup => $isDup,
				 taxonomyId => $orthTax, aaLength => $orthLen,
				 treeId => $treeId, ourBegin => $ourBeg, ourEnd => $ourEnd,
				 minOurBegin => $ourBeg, maxOurEnd => $ourEnd,
				 allTruncated => $truncated,
				 begin => $orthBeg, end => $orthEnd,
				 minBegin => $orthBeg, maxEnd => $orthEnd,
				 ogId => $ogId,
				 nGenes => $nGenes, nGenomes => $nGenomes,
				 nMemberThisGenome => $orthNThisGenome };
	}
    }
}

# Returns a named hash of locusId => locusId, version, taxonomyId, isOrth, ...
# isOrth will always be 1 because non-orthologs are filtered out, unless you set all
# See pertreeOrthologs() for more documentation.
# Optional parameters:
# useFastBLAST => 1 -- choose domains by using FastBLAST instead of by using Locus2Tree (slower)
# nOverlap => 3 -- #families per region; defaults to 3
# all => 1 -- return genes that are in an ortholog group but are not orthologs (with isOrth=0)
# taxa => [83333,83334] -- report orthologs only from the listed genomes
sub treeOrthologs {
    my ($self) = shift;
    my %params = @_;
    return {} unless defined $self && $self->isProtein;
    return $self->{treeOrth_} if exists $self->{treeOrth_};

    my $locusId = $self->locusId();
    my $version = $self->version();

    # Get the trees to use
    my ($ID,$NAME,$TYPE,$BEGIN,$END,$AA,$NALIGN,$SCORE) = (0..7);
    my @treeRows = (); # to use for finding orthologs
    if($params{useFastBLAST}) {
	my $fastBLASTDir=$defaults->{FastBLASTDataDir};
	FastBLAST::InitDomains($fastBLASTDir);
	my $domains = FastBLAST::FetchDomains(join("_",$locusId,$version));
	my $gooddom = TopDomains($domains);
	@treeRows = $self->treesForOrthologs($gooddom);
    } else {
	# Do not get actual metadata from Tree because it is slow to look up
	my $rows = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{SELECT treeId,treeId,treeId,begin,end,1,nAligned,score
					       FROM Locus2Tree
					       WHERE locusId=$locusId AND version=$version});
	my @rows = sort {$b->[$SCORE] <=> $a->[$SCORE]} @$rows;
	my $nOverlapLimit = $params{nOverlap} || 3;
	foreach my $row (@rows)  {
	    my $nOverlap = 0;
	    foreach my $old (@treeRows) {
		my $maxBeg = $row->[$BEGIN] > $old->[$BEGIN] ? $row->[$BEGIN] : $old->[$BEGIN];
		my $minEnd = $row->[$END] < $old->[$END] ? $row->[$END] : $old->[$END];
		$nOverlap++ if $minEnd - $maxBeg + 1 > 0.5 * ($row->[$END] - $row->[$BEGIN] + 1);
	    }
	    if ($nOverlap < $nOverlapLimit) {
		print STDERR "Keeping tree row " . join(" ",@$row) . "\n"
		    if Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() > 1;
		push @treeRows, $row;
	    } else {
		print STDERR "Skipping tree row " . join(" ",@$row) . "\n"
		    if Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() > 1;
	    }
	}
    }
    return {} if scalar(@treeRows) == 0;

    # Get orthologs for each tree
    my $orth = {};
    my $taxWithOrth = {};
    foreach my $treeRow (@treeRows) {
	# Writes to $orth and $taxWithOrth
	$self->pertreeOrthologs($treeRow, $orth, $taxWithOrth, $params{taxa});
    }

    # Require a gene's orthology relations to extend across 60% of the region
    # that is covered by the trees we use, and require a non-truncated hit
    my $aaLen = CORE::length( $self->protein() );
    # domId, seqId, seqBeg, seqEnd
    my $selfMin = Bio::KBase::ProteinInfoService::Vector::min(map {$_->[$BEGIN]} @treeRows);
    my $selfMax = Bio::KBase::ProteinInfoService::Vector::max(map {$_->[$END]} @treeRows);
    my $selfCoverage = $selfMax - $selfMin + 1;
    print STDERR "Locus $locusId aaLength $aaLen selfCoverage $selfCoverage\n"
	if Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() > 1;
    while (my ($orthId,$hit) = each %$orth) {
	$hit->{isOrth} = 0 unless $hit->{maxOurEnd} - $hit->{minOurBegin} + 1 >= 0.6 * $selfCoverage
	    && $hit->{allTruncated} == 0;
    }

    # Look for genes that are orthologs only because of a second-best tree, even though
    # they were in a better tree, according to which they are non-orthologs
    #
    my $bestRow = $treeRows[0];
    my %notBest = (); # orthId => 1 if not called by the best tree
    while (my ($orthId,$hit) = each %$orth) {
	next unless $hit->{isOrth}; # do not bother checking truncated genes, etc.
	$notBest{$orthId} = 1 unless $hit->{treeId} == $bestRow->[$ID]
	    && $hit->{ourBegin} == $bestRow->[$BEGIN]
	    && $hit->{ourEnd} == $bestRow->[$END];
    }
    my @notBest = keys(%notBest);
    if (scalar(@notBest) > 0) {
	my $notBestSpec = join(",", @notBest);
	my $treeSpec = join(",", map {$_->[$ID]} @treeRows);
	my $notBestTrees = Bio::KBase::ProteinInfoService::GenomicsUtils::query(qq{SELECT treeId,locusId FROM Locus2Tree
						       WHERE treeId IN ($treeSpec) AND locusId IN ($notBestSpec)});
	my %locus2Tree = (); # locusId => treeId => 1 if present in that tree
	foreach my $row (@$notBestTrees) {
	    my ($treeId,$orthId) = @$row;
	    $locus2Tree{$orthId}{$treeId} = 1;
	}

	# And now, check for orthologs that were in a better tree
	my %treeIdToN = map {$treeRows[$_][$ID] => $_} (0..(scalar(@treeRows)-1));

	while (my ($orthId,$orthTrees) = each %locus2Tree) {
	    my $minN = Bio::KBase::ProteinInfoService::Vector::min(map {$treeIdToN{$_}} keys %$orthTrees);
	    my $actualN = $treeIdToN{$orth->{$orthId}{treeId}};
	    if ($minN < $actualN) {
		$orth->{$orthId}{isOrth} = 0;
		print STDERR "Skipping putative orth $orthId by "
		    . join(" ", "id",$orth->{$orthId}{treeId},
			   $orth->{$orthId}{treeType},$orth->{$orthId}{treeName})
		    . " b/c is in better tree "
		    . join(" ", $treeRows[$minN][$ID], $treeRows[$minN][$TYPE], $treeRows[$minN][$NAME])
		    . "\n"
		    if Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() > 1;
	    }
	}
    }

    if (Bio::KBase::ProteinInfoService::GenomicsUtils::getDebug() > 1) {
	while (my ($orthId,$values) = each %$orth) {
	    print STDERR join("\t", "TreeOrth", $locusId, $version, $orthId, $values->{version},
			      $values->{isOrth},
			      $values->{treeId}, $values->{treeType}, 
			      $values->{treeName}, $values->{ogId}, $values->{isDup},
			      $values->{ourBegin}, $values->{ourEnd}, $values->{begin}, $values->{end},
			      $values->{taxonomyId},
			      $values->{minBegin}, $values->{maxEnd}, $values->{aaLength})."\n";
	}
    }

    # remove non-orthologs
    if(!$params{all}) {
	while (my ($orthId,$hit) = each %$orth) {
	    if (! $hit->{isOrth}) {
		delete $orth->{$orthId};
	    }
	}
    }
    $self->{treeOrth_} = $orth;
    return $orth;
}

sub DESTROY()
{
    
}

1;
