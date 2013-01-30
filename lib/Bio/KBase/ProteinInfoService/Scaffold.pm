package Bio::KBase::ProteinInfoService::Scaffold;

# $Id: Scaffold.pm,v 1.43 2011/05/31 22:34:36 kkeller Exp $

use strict;
require Exporter;

use DBI;
use Digest::MD5 qw (md5_hex);

use Bio::KBase::ProteinInfoService::GenomicsUtils;
use Bio::KBase::ProteinInfoService::Gene;
#use Bio::KBase::ProteinInfoService::Browser::DB;
#use Bio::KBase::ProteinInfoService::Browser::Defaults;

use vars qw(@ISA @EXPORT);
 
 
@ISA = qw(Exporter);	
@EXPORT = qw( fetchGenesList fetchGenesListRef fetchGenesMap fetchGenesMapRef );


sub new;
# Creates scaffold object.
# Parameters:
#   scaffoldId => ID, preload => [FEATURES]
#---------------------------------------------------------
# Private variables
#
#     $self->{scaffoldId_} 
#     $self->{chrNumber_} 
#     $self->{taxonomy_} 
#     $self->{length_} 
#     $self->{file_} 
#     $self->{sequence_} 
#     $self->{genes_} - list of genes in order
#     $self->{genesMap_} - hash of genes keyed on locusId
#

#---------------------------------------------------------
#The following functions just retrieve basic info, and should
#be self-explanatory
sub comment();
sub chrNumber(); # Returns number of the chromosome
sub taxonomyId();
sub taxonomyName();
sub length(); # Returns length of the scaffold sequence in bp
sub isCircular();
sub isPartial();
sub isGenomic();
sub isActive();
sub file(); # Returns file name where this scaffold is located
sub sequenceRef();# Returns a reference to genomic DNA sequence
sub sequence();
sub md5sum; # Returns an MD5 sum of the raw sequence

# Fetches a portion of the genome from begin to end; handles wrap-around if optional 3rd argument is set
# Otherwise, if begin < end, it does reverse complement
# Positions are 1-based
sub subsequence();
#---------------------------------------------------------

sub genesRef();
sub genes();
#Returns (reference to) a list of all genes in this scaffold

#---------------------------------------------------------
sub fetchGenesList;
sub fetchGenesListRef;
#Returns (reference to) a list of gene objects sorted by start
#position.
#fetchGenesListRef is the engine behind all of the gene-creating
#functions in this section.  All the preload options are handled here,
#and all of the SQL queries to load gene objects are handled by this
#function. Relies on Gene::new() to actually create gene objects.
#This is a seriously long and comlpicated function - avoid it at all
#costs.

sub fetchGenesMap;
sub fetchGenesMapRef;
#Returns (reference to) a map of gene objects keyed on locusId.  Uses
#fetchGenesListRef to collect gene objects.

#---------------------------------------------------------

sub genes();
sub genesRef();
#These functions return a list of genes found on this scaffold.
#makeGenesList is used to create the list, and relies on
#fetchGenesListRef to actually make the gene objects.

sub genesMap();
sub genesMapRef();
#These functions return the same genes as the other functions in this
#section, but in the form of a hash indexed by locusId.

sub makeGenesList;
#Creates the internal list of gene objects for the scaffold -
#$self->{genes_}.  Used by the preceding functions.

#---------------------------------------------------------

sub toString;
# Returns string describing the scaffold. 

sub getScaffoldList;
sub getScaffoldMap;
#Returns a list or hash of all scaffold objects

# this may be causing a memory leak
# it will only be used if cacheScaffolds=>1 is passed in to new()
my %scaffolds;
#my %defaultPreload;

sub new{
    my %params = @_;
    my $scaffoldId = $params{'scaffoldId'};
    my @preload;
    @preload = @{$params{'preload'}} if defined $params{'preload'};

    my $existing =  $scaffolds{$scaffoldId};
    if( defined($existing) ) {
#fix this logic to load only when preload is defined for synonym
	$existing->preloadSynonym() if ( @preload && !defined( $existing->{preloadSynonym_} ) );
	return $existing;
    }
    my $self = {};
    bless $self;
    my ($chrNumber, $length, $file,
	$taxonomyId, $taxonomyName, $taxShortName, $isCircular,
	$isPartial, $isGenomic, $isActive,
	$comment ) =  Bio::KBase::ProteinInfoService::Browser::DB::dbHandle()->selectrow_array( qq/ SELECT chr_num, length, file, s.taxonomyId, t.name, t.shortName,
							     isCircular, isPartial, isGenomic, isActive, comment
							     FROM Scaffold s, Taxonomy t WHERE scaffoldId='$scaffoldId' AND s.taxonomyId=t.taxonomyId / );

    $self->{scaffoldId_} = $scaffoldId;
    $self->{chrNumber_} = $chrNumber;
    $self->{taxonomyId_} = $taxonomyId;
    $self->{taxonomyName_} = $taxonomyName;
    $self->{taxonomyShortName_} = $taxShortName;
    $self->{length_} = $length;
    $self->{file_} = $file;
    $self->{isCircular_} = $isCircular;
    $self->{isPartial_} = $isPartial;
    $self->{isGenomic_} = $isGenomic;
    $self->{isActive_} = $isActive;
    $self->{comment_} = $comment;
    $self->{preloadSynonym_}=0;

	# kkeller: this causes a memory leak if looking at large
	# number of genomes
    $scaffolds{$scaffoldId} = $self if ($params{'cacheScaffolds'});

    $self->makeGenesList( preload => \@preload ) if( @preload );
    return $self;
}

sub comment()
{
    my $self = shift;
    return $self->{comment_};
}

sub scaffoldId(){
    my $self = shift;
    return $self->{scaffoldId_};
}

sub chrNumber() {
    my $self = shift;
    return $self->{chrNumber_};
}

sub taxonomyId(){
    my $self = shift;
    return $self->{taxonomyId_};
}
sub taxonomyName(){
    my $self = shift;
    return $self->{taxonomyName_};
}
sub taxonomyShort(){
    my $self = shift;
    return $self->{taxonomyShortName_};
}
sub length(){
    my $self = shift;
    return $self->{length_};
}

sub file() {
    my $self = shift;
    return $self->{file_};
}

sub isCircular(){
    my $self = shift;
    return $self->{isCircular_};
}

sub isPartial(){
    my $self = shift;
    return $self->{isPartial_};
}

# Compute the distance from the $pos1 to $pos2, corrected for circularity
# can return a negative value (never goes more than half-way round the chromosome if it's circular)
sub distance($ $) {
    my $self = shift;
    my $pos1 = shift;
    my $pos2 = shift;
    return ($pos2-$pos1)
	if ($self->isPartial() || !$self->isCircular() || abs($pos2-$pos1) < $self->length()/2);
    return $self->length()+$pos2-$pos1 if $pos2 < $pos1;
    return -$self->length() + $pos2-$pos1;
}

sub isGenomic(){
    my $self = shift;
    return $self->{isGenomic_};
}

sub isActive(){
    my $self = shift;
    return $self->{isActive_};
}

sub sequence(){
    my $self = shift;
    return ${$self->sequenceRef()};
}

sub sequenceRef(){
    my $self = shift;
    if ( !defined( $self->{sequence_} ) ) {
	my $scaffoldId = $self->{scaffoldId_}; 
	$self->{sequence_} =
	    \ Bio::KBase::ProteinInfoService::GenomicsUtils::query( qq/SELECT sequence FROM ScaffoldSeq
				  WHERE scaffoldId=$scaffoldId/ )->[0][0];
    } 
    return $self->{sequence_}; 
}

sub md5sum {
	my $self=shift;
	my $seqR=$self->sequenceRef;
	# don't want to return a bogus MD5 if there's no sequence
	return undef unless (ref $seqR);

	# the exact details of what gets stuffed into the MD5 sum
	# will be worked out with SEED developers
	return md5_hex(uc($$seqR));
}

# unlike subseq, this does not fetch the whole sequence
# note end is inclusive and arguments are 1-based
# there is a wrap argument, but it will refuse to wrap if the sequence is  
sub subsequence() {
    my $self = shift;

	# some scaffolds do not have an associated ScaffoldSeq entry
	return undef unless ($self->sequence);

    my $begin = shift;
    my $end = shift;
    my $wrap = @_ > 0 ? shift @_ : 0;
    $wrap = $wrap && $self->isCircular() && !$self->isPartial();

    if ($begin < 1 && $wrap) {
		$begin = $self->length + $begin;
    }
    if ($end > $self->length && $wrap) {
		$end -= $self->length;
    }
    die "Illegal begin value $begin in subsequence($begin,$end,$wrap)" if $begin < 1;
    die "Illegal end value $end in subsequence($begin,$end,$wrap)" if $end > $self->length;
    if ($begin > $end && $wrap) {
	return $self->subsequence($begin,$self->length(),0) . $self->subsequence(1,$end,0);
    } else {
	my $start = $begin < $end ? $begin : $end;
	my $len = abs($end-$begin) + 1;
	my $scaffoldId = $self->{scaffoldId_}; 
	my $seq = Bio::KBase::ProteinInfoService::GenomicsUtils::queryScalar(qq{SELECT SUBSTRING(sequence,$start,$len) FROM ScaffoldSeq
						    WHERE scaffoldId = $scaffoldId});
	return( $begin > $end ? Bio::KBase::ProteinInfoService::GenomicsUtils::reverseComplement($seq) : $seq );
    }
}

# arguments are $begin, $end (inclusive) and are 1-based
# returns the reverse complement if $begin > $end
sub subseq() {
    my ($self, $begin, $end) = @_;
    my $ref = $self->sequenceRef();
    $begin--;
    $end--;
    return substr($$ref, $begin, 1+$end-$begin) if ($begin < $end);
    #else
    return Bio::KBase::ProteinInfoService::GenomicsUtils::reverseComplement(substr($$ref, $end, 1+$begin-$end));
}

sub genes(){
    return @{&genesRef(@_)};
}

sub hasLoadedGenes {
    my $self = shift;
    return defined $self->{genes_} ? 1 : 0;
}

sub genesRef(){
    my $self = shift;
    
    if(! defined $self->{genes_}) {
	$self->makeGenesList(@_);
    }
    return $self->{genes_};
}

sub genesMap(){
    my $self = shift;
    return %{$self->genesMapRef()};
}

sub genesMapRef(){
    my $self = shift;

    if(! defined $self->{genesMap_}){
	$self->{genesMap_} = {map {$_->locusId(),$_} @{$self->genesRef()}};
    }
    return $self->{genesMap_};
}

sub makeGenesList{
    my $self = shift;

    if( !defined($self->{genes_}) ) {
	my $genes = fetchGenesListRef( scaffoldId =>
				       [$self->{scaffoldId_}], @_);
	my $i = 0;
	$self->{genes_} = [ sort { $a->begin <=> $b->begin() }
			    map { # $_->setScaffold( $self ); # not needed b/c scaffold is preloaded
				  $_->setIndex( $i++ ); $_  } @$genes];
    }
}

sub fetchGenesMap{
    return %{&fetchGenesMapRef(@_)};
}

sub fetchGenesMapRef {
    my %params = @_;
    my $self = $params{self};
    my %genesMap;

    my $genes = &fetchGenesListRef(@_);
    foreach my $gene (@$genes){
 	$genesMap{$gene->locusId()}=$gene;
    }
    return \%genesMap;
}

sub fetchGenesList{
    return @{&fetchGenesListRef(@_)};
}

sub fetchGenesListRef{
    my %params = @_;
    my @query = ();

    if (defined($params{taxonomyId})) {
	my $tax = $params{taxonomyId};
	my $restriction = join " , ", @$tax;
	$restriction = " s.taxonomyId in (" . $restriction  . ") ";
	push @query, $restriction;
    }
    if ( defined($params{scaffoldId}) ) {
	my $scaffolds = $params{scaffoldId};
	my $restriction = join " , ", @$scaffolds;
	$restriction = " s.scaffoldId in (" . $restriction  . ") ";
	push @query, $restriction;
    }
    if (defined($params{chrNumber})){
	push @query, qq{s.chr_num="$params{chrNumber}"};
    }
    if (defined($params{begin})) {
	push @query, qq{p.start > $params{begin}};
    }
    if (defined($params{end})) {
	push @query, qq{p.stop < $params{end}};
    }
    if (defined($params{locusId})) {
	my $locuss = $params{locusId};
	my $nOrfs = scalar( @$locuss ); # number of elements in the list
	if( defined($params{version}) ) {
	    my $versions = $params{version};
	    die "Number of locuss is not equal to number of versions\n" if scalar(@$versions)!=$nOrfs;
	    my @conditions;
	    for(my $i=0; $i < $nOrfs; ++$i) {
		push @conditions, qq/ (o.locusId=$$locuss[$i] and o.version=$$versions[$i])/;
	    }
	    my $restriction = join " or ", @conditions;
	    $restriction = "( " . $restriction . " )";
	    push @query, $restriction;
	}
	else {
	    my $restriction = join " , ", @$locuss;
	    $restriction = "o.locusId in (" . $restriction  . ")";
	    push @query, $restriction;
	}
    }

    push @query, "o.priority=1" unless defined($params{version});

    my $query = join " AND ", @query;
    my $statement = qq/SELECT p.begin, p.end, p.strand, o.locusId, o.version, o.posId, o.type, c.cogInfoId, s.scaffoldId FROM Scaffold s, Position p, Locus o  LEFT JOIN COG c ON (o.locusId=c.locusId AND o.version=c.version) WHERE $query AND p.scaffoldId=s.scaffoldId AND o.posId=p.posId ORDER BY s.scaffoldId, begin, o.locusId/;
    my $refGenes = Bio::KBase::ProteinInfoService::GenomicsUtils::query( $statement );
    my @loci = map { $_->[3] } @$refGenes;
    return [] if @loci==0;
    my $locusReqShort = "locusId IN (".join(",",@loci).")";
    my $locusReq = "o.$locusReqShort";
    if (defined $params{version}) {
	$locusReq .= " AND o.version=".$params{version};
    } else {
	$locusReq .= " AND o.priority=1";
    }

    my %preloaded;
    if (defined($params{preload})) {
	my $preloadsRef = $params{preload};
	foreach my $feature (@$preloadsRef) {
	    if( $feature eq 'synonym' ) {
		# note: module does not support multiple values for a synonym, so join them by ","
		$statement = qq/SELECT DISTINCT o.locusId, sy.name, sy.type  FROM Locus o JOIN Synonym sy ON (o.locusId=sy.locusId AND o.version=sy.version) WHERE $locusReq/;
		my $synonymRef = {};
		foreach my $row (@{ Bio::KBase::ProteinInfoService::GenomicsUtils::query( $statement ) }) {
		    my ($locusId,$name,$type) = @$row;
		    $synonymRef->{$locusId} = {} unless exists $synonymRef->{$locusId};
		    if (exists $synonymRef->{$locusId}{$type}) {
			$synonymRef->{$locusId}{$type} .= "," . $name;
		    } else {
			$synonymRef->{$locusId}{$type} = $name;
		    }
		}
		$preloaded{synonym} =  $synonymRef;
	    } elsif( $feature eq 'description' ) {
		$statement = qq/SELECT o.locusId, a.description, a.source 
		                FROM Locus o JOIN Description a USING (locusId,version)
				WHERE $locusReq/;
		my $results =  Bio::KBase::ProteinInfoService::GenomicsUtils::query( $statement );
		my $descriptionHash = {};
		foreach (@$results) {
		    $descriptionHash->{$_->[0]} = $_->[1]. " (" . $_->[2] . ")";
		}
		$preloaded{description} =  $descriptionHash;
	    } elsif ( $feature eq 'ortholog' ) {
		$statement = qq{SELECT o.locusId,
				p2.begin, p2.end, p2.strand, o2.locusId, o2.version, o2.type,
				o2.posId, c2.cogInfoId, p2.scaffoldId,
				m1.mogId, m2.taxonomyId
				FROM Locus o JOIN MOGMember m1 ON o.locusId=m1.locusId
				JOIN MOGMember m2 ON m1.mogId=m2.mogId
				JOIN Locus o2 ON o2.locusId=m2.locusId AND o2.priority=1
				JOIN Position p2 ON o2.posId=p2.posId
				LEFT JOIN COG c2 ON (o2.locusId=c2.locusId AND o2.version=c2.version)
				WHERE $locusReq};
		# Note we include self-hits so mogTax also tells us if this is unique
		# in the self genome
		my %mogTax = (); # mogId => tax2 => list of locus2
		my %selfTax = (); # locus1 => tax1
		my $results = Bio::KBase::ProteinInfoService::GenomicsUtils::query($statement);
		foreach my $row (@$results) {
		    my ($locusId, $start2, $stop2, $strand2, $locusId2,
			$version2, $type2, $posId2, $cog2, $scaffold2,
			$mogId, $taxonomyId2) = @$row;
		    push @{ $mogTax{$mogId}{$taxonomyId2} }, $locusId2;
		    $selfTax{$locusId} = $taxonomyId2 if $locusId == $locusId2;
		}
		my @filtered = ();
		foreach my $row (@$results) {
		    my ($locusId, $start2, $stop2, $strand2, $locusId2,
			$version2, $type2, $posId2, $cog2, $scaffold2,
			$mogId, $taxonomyId2) = @$row;
		    next if $locusId == $locusId2
			|| scalar(@{ $mogTax{$mogId}{$selfTax{$locusId}} }) > 1
			|| scalar(@{ $mogTax{$mogId}{$taxonomyId2} }) > 1;
		    push @filtered, $row;
		}
		@filtered = sort { $a->[9] <=> $b->[9] } @filtered;

		my $orthologsRef = {};
		foreach my $row (@filtered) {
		    my ($locusId, $start2, $stop2, $strand2, $locusId2,
			$version2, $type2, $posId2, $cog2, $scaffold2) = @$row;
		    my $gene = Bio::KBase::ProteinInfoService::Gene::new( begin => $start2, end => $stop2,
					  strand => $strand2, locusId => $locusId2,
					  version => $version2, type => $type2, posId => $posId2,
					  cogInfoId => $cog2, scaffoldId => $scaffold2 );
		    Bio::KBase::ProteinInfoService::GenomicsUtils::addToHashList($orthologsRef, $locusId, $gene);
		}
		$preloaded{ortholog} = $orthologsRef;
	    } elsif ($feature eq 'ec') {
		$statement = qq/SELECT o.locusId, l2ec.ecNum, ec.name, l2ec.evidence
		                FROM Locus o JOIN Locus2Ec l2ec USING (locusId,version)
				JOIN ECInfo ec USING (ecNum)
				WHERE $locusReq/;
		my $ecRef = {}; # locusId -> ec -> list, -> ecNum -> list
		foreach (@{ Bio::KBase::ProteinInfoService::GenomicsUtils::query($statement) }) {
		    my ($locusId,$ecNum,$name,$evidence) = @$_;
		    $ecRef->{$locusId} = {'ec'=>[], 'ecNum'=>[]} unless exists $ecRef->{$locusId};
		    # this odd format is how Gene::ec returns ec values
		    push @{ $ecRef->{$locusId}{'ec'} }, join("\t",$ecNum,$name,defined $evidence? "($evidence)" : "");
		    push @{ $ecRef->{$locusId}{'ecNum'} }, $ecNum;
		}
		$preloaded{ec} = $ecRef;
	    } elsif ($feature eq 'go') {
		die "Cannot preload go information if specifying version" if exists $params{version};
		$statement = qq/SELECT o.locusId, t.term_type, t.acc, t.name, o.evidence
		    FROM Locus2Go o, term t WHERE o.$locusReqShort AND o.goId=t.id ORDER BY term_type/;
		my $goRef = {}; # locusId->list
		foreach (@{ Bio::KBase::ProteinInfoService::GenomicsUtils::query($statement) }) {
		    my ($locusId, $type, $acc, $name, $evidence) = @$_;
		    $type =~ s/molecular_function/[M]/; 
		    $type =~ s/cellular_component/[C]/;
		    $type =~ s/biological_process/[B]/;
		    my $go = join(" ",$type,$acc,$name,"($evidence)");
		    $goRef->{$locusId} = [] unless exists $goRef->{$locusId};
		    push @{ $goRef->{$locusId} }, $go;
		}
		$preloaded{go} = $goRef;
	    } elsif ($feature eq 'ipr') {
		die "Cannot preload ipr information if specifying version" if exists $params{version};
		my $statement = qq/SELECT locusId, l2i.iprId, iprName
		                   FROM Locus2Ipr l2i JOIN IPRInfo USING (iprId)
				   WHERE $locusReqShort/;
		my $iprRef = {};
		foreach (@{ Bio::KBase::ProteinInfoService::GenomicsUtils::query($statement) }) {
		    my ($locusId,$id,$name) = @$_;
		    $iprRef->{$locusId} = [] unless exists $iprRef->{$locusId};
		    push @{ $iprRef->{$locusId} }, "$id: $name";
		}
		$preloaded{ipr} = $iprRef;
	    } elsif ($feature eq 'COGInfo') {
		my $statement = qq/SELECT STRAIGHT_JOIN o.locusId, funCode, description
		                   FROM Locus o JOIN COG USING (locusId,version) JOIN COGInfo USING (cogInfoId)
				   WHERE $locusReq/;
		my $COGInfoRef = {}; # locusId->[code,desc]
		foreach (@{ Bio::KBase::ProteinInfoService::GenomicsUtils::query($statement) }) {
		    my ($locusId,$funCode, $desc) = @$_;
		    $COGInfoRef->{$locusId} = [$funCode,$desc];
		}
		$preloaded{COGInfo} = $COGInfoRef;
	    } else {
		die "Unknown feature $feature";
	    }
	}
    }

    my @genes = ();
    foreach my $refRow (@$refGenes){
	my ( $start, $stop, $strand,
	     $locusId, $version, $posId, $type, $cog, $scaffoldId ) = @$refRow;
	my @params = ( begin => $start, end => $stop,
		       strand => $strand, locusId => $locusId,
		       version => $version, posId => $posId, type => $type,
		       cogInfoId => $cog, scaffoldId => $scaffoldId );
	if (exists $preloaded{synonym}) {
	    my $syn = exists $preloaded{synonym}{$locusId} ? $preloaded{synonym}{$locusId} : {};
	    push @params, ( synonym => $syn );
	}
	if (exists $preloaded{description}) {
	    my $desc = exists $preloaded{description}{$locusId} ? $preloaded{description}{$locusId} : "";
	    push @params, ( description => $desc);
	}
	if (exists $preloaded{ec}) {
	    my $ec = exists $preloaded{ec}{$locusId} ? $preloaded{ec}{$locusId}{ec} : [];
	    my $ecNum = exists $preloaded{ec}{$locusId} ? $preloaded{ec}{$locusId}{ecNum} : [];
	    push @params, ( ec => $ec, ecNum => $ecNum );
	}
	if (exists $preloaded{go}) {
	    my $go = exists $preloaded{go}{$locusId} ? $preloaded{go}{$locusId} : [];
	    push @params, ( go => $go );
	}
	if (exists $preloaded{ipr}) {
	    my $ipr = exists $preloaded{ipr}{$locusId} ? $preloaded{ipr}{$locusId} : [];
	    push @params, ( ipr => $ipr );
	}
	if (exists $preloaded{COGInfo}) {
	    my $row = $preloaded{COGInfo}{$locusId};
	    push @params, ( cogFun => (defined $row ? $row->[0] : ""),
			    cogDesc => (defined $row? $row->[1] : "") );
	}
	if (exists $preloaded{ortholog}) {
	    push @params, ( orthologListRef => ( exists $preloaded{ortholog}->{$locusId} ?
						 $preloaded{ortholog}->{$locusId} : [] ) );
	}
	my $gene = Bio::KBase::ProteinInfoService::Gene::new( @params );
	push @genes, $gene;
    }
    return \@genes;
}

sub toString{
    my $self = shift;
    return "[".$self->{scaffoldId_}."] ".$self->{file_}; 
}

sub getScaffoldList{
    return map { &Bio::KBase::ProteinInfoService::Scaffold::new( scaffoldId => $_ ) }
    sort {$a<=>$b} &queryList( qq/ SELECT scaffoldId FROM
			       Scaffold WHERE isActive=1/ );
}

sub getScaffoldMap{
    return map { $_->scaffoldId(), $_ } &getScaffoldList;
}

#---------------------------------------------------------------------
#Preload features
#MNP 3/15/04 -- I think it is OK now

sub preloadSynonym(){
    my $self = shift;
    my $scaffoldId = $self->{scaffoldId_};

# Trying to recreate the statement 
    my $statement = qq/SELECT o.locusId, sy.name, sy.type  FROM Scaffold s, Position p, Locus o LEFT JOIN Synonym sy ON (o.locusId=sy.locusId AND o.version=sy.version) WHERE s.scaffoldId=$scaffoldId AND p.scaffoldId=s.scaffoldId AND o.posId=p.posId  ORDER BY begin, locusId/;
    my $synonymRef = Bio::KBase::ProteinInfoService::GenomicsUtils::query( $statement );
    my $genesRef = $self->genesRef();
    foreach my $g (@$genesRef) {
	my $synonymHashRef = createSynonymHash( $synonymRef, $g->locusId()  );
	$g->setSynonym( $synonymHashRef );
    }
    $self->{preloadSynonym_}=1;
}

# MNP 10/20/03 - Fixed to remove elements from the input synonymRef
sub createSynonymHash( $ $ ) {
    my ( $synonymRef, $locusId ) = @_;

    # synonymRef has the following structure  o.locusId, s.name, s.type
    my %synonymHash;

    while ( scalar @{ $synonymRef } > 0 &&
	    $locusId == $synonymRef->[0][0] ) {
	my $row = shift @{ $synonymRef };
	# If some genes lack synonyms then LEFT JOIN will ensure that something is returned...
	$synonymHash{ $row->[2] } = $row->[1] if defined $row->[2];
    }
    return \%synonymHash;
}

# pass in the comment, isPartial, and (optional) isGenomic flags and this will compute a short name for the scaffold
# if the scaffold does not have an informative comment (which is often the case for the main chromosome
# of a complete genome) then the short name will be empty
sub ScaffoldName {
    my ($comment,$partial,$isGenomic) = @_;


    if (!defined $comment) {
        return "";
    } elsif (defined $partial && $partial) {
        return "contig";
    } elsif ($comment =~ m/(m?e?g?a?plasmid .*),/) {
        return $1;
    } elsif ($comment =~ m/(m?e?g?a?plasmid .*)$/) {
        return $1;
    } elsif ($comment =~ m/megaplasmid/) {
        return "megaplasmid";
    } elsif ($comment =~ m/(chromosome .*),/) {
        return $1;
    } elsif ($comment =~ m/(chromosome .*)/) {
        return $1;
    } elsif (defined $isGenomic && $isGenomic eq "0") {
	return "plasmid";
    } else {
        return "";
    }
}

sub genesWithin {
    my ($self,$begin,$end) = @_;
    die unless defined $end;
    my $kbt1 = int($begin/10000);
    my $kbt2 = int($end/10000);
    my $kbtlist = join(",",$kbt1..$kbt2);
    my $scaffoldId = $self->scaffoldId();
    my $query = qq{SELECT DISTINCT p.begin,p.end,p.strand,l.locusId,l.version,p.posId,l.type,c.cogInfoId
		       FROM ScaffoldPosChunks spc
		       JOIN Locus l USING (locusId,version)
		       JOIN Position p ON spc.posId=p.posId
		       LEFT JOIN COG c ON c.locusId=l.locusId AND c.version=l.version
		       WHERE spc.scaffoldId = $scaffoldId
		       AND spc.kbt IN ($kbtlist)
		       AND l.priority=1
		       ORDER BY p.begin
		   };
    my @out = ();
    foreach my $row (@{ Bio::KBase::ProteinInfoService::GenomicsUtils::query($query) }) {
	my ($begin,$end,$strand,$locusId,$version,$posId,$type,$cog) = @$row;
	push @out, Bio::KBase::ProteinInfoService::Gene::new(scaffoldId => $scaffoldId,
			     locusId => $locusId, version => $version,
			     begin => $begin, end => $end, strand => $strand, posId => $posId,
			     cogInfoId => $cog, type => $type);
    }
    return(@out);
}

1;

