package Bio::KBase::ProteinInfoService::Impl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

ProteinInfo

=head1 DESCRIPTION

This module provides various annotations about proteins, including
domain annotations, orthologs in other genomes, and operons.

=cut

#BEGIN_HEADER

use LWP::UserAgent;
use JSON;

use Bio::KBase;
use Bio::KBase::MOTranslationService::Client;
use DBKernel;

#use ContextAdapter;

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

	my $kb = Bio::KBase->new();
#	my $kbIdServer = $kb->id_server();
	my $kbCDM = $kb->central_store;
	my $kbMOT = Bio::KBase::MOTranslationService::Client->new('http://localhost:7061');
#	my $moDbh=DBI->connect("DBI:mysql:genomics:db1.chicago.kbase.us",'genomics');

	my $dbms='mysql';
	my $dbName='genomics';
	my $user='genomics';
	my $pass=undef;
	my $port=3306;
	my $dbhost='db1.chicago.kbase.us';
	my $sock='';
	my $moDbh = DBKernel->new($dbms, $dbName, $user, $pass, $port, $dbhost, $sock);

#	$self->{kbIdServer}=$kbIdServer;
	$self->{kbCDM}=$kbCDM;
	$self->{kbMOT}=$kbMOT;
	$self->{moDbh}=$moDbh;

    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 fids_to_operons

  $return = $obj->fids_to_operons($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is an operon
fid is a string
operon is a reference to a list where each element is a fid

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is an operon
fid is a string
operon is a reference to a list where each element is a fid


=end text



=item Description

fids_to_operons takes as input a list of feature
ids and returns a mapping of each fid to the operon
in which it is found. The list of fids in the operon
is not necessarily in the order that the fids are found
on the genome.  (fids_to_operons is currently not properly
implemented.)

=back

=cut

sub fids_to_operons
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_operons:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_operons');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_operons

	$return={};

	if (scalar @$fids)
	{
#		my $ctxA = ContextAdapter->new($ctx);
#		my $user_token = $ctxA->user_token();

		my $moDbh=$self->{moDbh};
		my $kbCDM=$self->{kbCDM};
		my $kbMOT=$self->{kbMOT};

		my $externalIds=$kbMOT->fids_to_moLocusIds($fids);

		my $operons={};
		foreach my $kbId (keys %$externalIds)
		{
			my $placeholders='?,' x (scalar @{$externalIds->{$kbId}});
			chop $placeholders;
			my $operonSql="SELECT o2.locusId
		       		FROM Locus2Operon o1, Locus2Operon o2
				WHERE o1.locusId IN ($placeholders)
				AND o1.tuId=o2.tuId
				ORDER BY o2.locusId";

			# this is currently the only ProteinInfo method
			# that needs to return genes from the same genome
			# so doing this as a one-off is not horrible
			# (it will be replaced by ER methods anyway once
			# operons are a data type in KBase land)

			my $operonLocusIdList=$moDbh->selectcol_arrayref($operonSql,{},@{$externalIds->{$kbId}}) || [];
			my $moOperonIds_to_kbaseIds=$kbMOT->moLocusIds_to_fids($operonLocusIdList);

			my $genomes=$kbCDM->fids_to_genomes([$kbId]);
			my $genome=$genomes->{$kbId};

			my $kbOperonIds;
			# craziness: try to limit operon to the original genome
			# potentially different operons are called in
			# different genomes
			foreach my $moOperonId (keys %$moOperonIds_to_kbaseIds)
			{
				my $operonGenomes=$kbCDM->fids_to_genomes($moOperonIds_to_kbaseIds->{$moOperonId});
				foreach my $kbOperonId (keys %$operonGenomes)
				{
					my $operonGenome=$operonGenomes->{$kbOperonId};
					$kbOperonIds->{$kbOperonId}=1 if ($genome eq $operonGenome);
				}
			}

			my @kbOperonIds=keys %$kbOperonIds;
			$operons->{$kbId}=\@kbOperonIds || [$kbId];
		}
		$return=$operons|| {};
	}

    #END fids_to_operons
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_operons:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_operons');
    }
    return($return);
}




=head2 fids_to_domains

  $return = $obj->fids_to_domains($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is a domains
fid is a string
domains is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is a domains
fid is a string
domains is a reference to a list where each element is a string


=end text



=item Description

fids_to_domains takes as input a list of feature ids, and
returns a mapping of each fid to its domains. (This includes COG,
even though COG is not part of InterProScan.)

=back

=cut

sub fids_to_domains
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_domains:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_domains');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_domains

	$return={};

	if (scalar @$fids)
	{
#		my $ctxA = ContextAdapter->new($ctx);
#		my $user_token = $ctxA->user_token();

		my $moDbh=$self->{moDbh};
		my $kbMOT=$self->{kbMOT};

		my $fids2externalIds=$kbMOT->fids_to_moLocusIds($fids);

		# this is not the best way, but should work
		foreach my $fid (keys %$fids2externalIds)
		{
			my $domainSql='SELECT DISTINCT locusId,domainId FROM Locus2Domain WHERE
				locusId = ?';
#			my $placeholders='?,' x (@{$fids2externalIds->{$fid}});
#			chop $placeholders;
#			$sql.=$placeholders.')';
		
			my $domainSth=$moDbh->prepare($domainSql);
			$domainSth->execute($fids2externalIds->{$fid}[0]);
			while (my $row=$domainSth->fetch)
			{
				push @{$return->{$fid}},$row->[1];
			}

			my $cogSql='SELECT DISTINCT locusId,CONCAT("COG",cogInfoId) FROM COG WHERE
				locusId = ?';
		
			my $cogSth=$moDbh->prepare($cogSql);
			$cogSth->execute($fids2externalIds->{$fid}[0]);
			while (my $row=$cogSth->fetch)
			{
				push @{$return->{$fid}},$row->[1];
			}

		}
	}

    #END fids_to_domains
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_domains:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_domains');
    }
    return($return);
}




=head2 domains_to_fids

  $return = $obj->domains_to_fids($domain_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$domain_ids is a domains
$return is a reference to a hash where the key is a domain_id and the value is a reference to a list where each element is a fid
domains is a reference to a list where each element is a string
domain_id is a string
fid is a string

</pre>

=end html

=begin text

$domain_ids is a domains
$return is a reference to a hash where the key is a domain_id and the value is a reference to a list where each element is a fid
domains is a reference to a list where each element is a string
domain_id is a string
fid is a string


=end text



=item Description

domains_to_fids takes as input a list of domain_ids, and
returns a mapping of each domain_id to the fids which have that
domain. (This includes COG, even though COG is not part of
InterProScan.)

=back

=cut

sub domains_to_fids
{
    my $self = shift;
    my($domain_ids) = @_;

    my @_bad_arguments;
    (ref($domain_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"domain_ids\" (value was \"$domain_ids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to domains_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'domains_to_fids');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN domains_to_fids

	$return={};
	
	my $moDbh=$self->{moDbh};
	my $kbMOT=$self->{kbMOT};

	if (scalar @$domain_ids)
	{

		# again, not ideal, but at least workable
		# possible idea: use kinosearch for this?
		foreach my $domainId (@$domain_ids)
		{
			$return->{$domainId}=[];
			my $domainSql='SELECT DISTINCT locusId FROM Locus2Domain WHERE
				domainId = ?';
		
			my $domainSth=$moDbh->prepare($domainSql);
			$domainSth->execute($domainId);
			my @externalIds;
			while (my $row=$domainSth->fetch)
			{
				push @externalIds,$row->[0];
			}

			my ($cogInfoId)=$domainId=~/^COG(\d+)$/;
			if ($cogInfoId)
			{
				my $cogSql='SELECT DISTINCT locusId FROM COG WHERE
					cogInfoId = ?';
		
				my $cogSth=$moDbh->prepare($cogSql);

				$cogSth->execute($cogInfoId);
				while (my $row=$cogSth->fetch)
				{
					push @externalIds,$row->[0];
				}
			}

			if (scalar @externalIds)
			{
				my $extIds2fids=$kbMOT->moLocusIds_to_fids(\@externalIds);
				my $domain_fids={};
				foreach my $extId (keys %$extIds2fids)
				{
					# this is an arrayref
					my $fids=$extIds2fids->{$extId};
					map {$domain_fids->{$_} = $_} @$fids;
				}

				my @domain_fids=keys $domain_fids;
				$return->{$domainId} = \@domain_fids;
			}
		}

	}
	
    #END domains_to_fids
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to domains_to_fids:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'domains_to_fids');
    }
    return($return);
}




=head2 fids_to_ipr

  $return = $obj->fids_to_ipr($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is an ipr
fid is a string
ipr is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is an ipr
fid is a string
ipr is a reference to a list where each element is a string


=end text



=item Description

fids_to_ipr takes as input a list of feature ids, and returns
a mapping of each fid to its IPR assignments. These can come from
HMMER or from non-HMM-based InterProScan results.

=back

=cut

sub fids_to_ipr
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_ipr:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_ipr');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_ipr

	$return={};

	if (scalar @$fids)
	{
#		my $ctxA = ContextAdapter->new($ctx);
#		my $user_token = $ctxA->user_token();

		my $moDbh=$self->{moDbh};
		my $kbMOT=$self->{kbMOT};

		my $fids2externalIds=$kbMOT->fids_to_moLocusIds($fids);

		# this is not the best way, but should work
		foreach my $fid (keys %$fids2externalIds)
		{
			my $iprSql='SELECT DISTINCT locusId,iprId FROM Locus2Ipr WHERE
				locusId = ?';
#			my $placeholders='?,' x (@{$fids2externalIds->{$fid}});
#			chop $placeholders;
#			$sql.=$placeholders.')';
		
			my $iprSth=$moDbh->prepare($iprSql);
			$iprSth->execute($fids2externalIds->{$fid}[0]);
			while (my $row=$iprSth->fetch)
			{
				push @{$return->{$fid}},$row->[1];
			}

		}
	}

    #END fids_to_ipr
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_ipr:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_ipr');
    }
    return($return);
}




=head2 fids_to_orthologs

  $return = $obj->fids_to_orthologs($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is an orthologs
fid is a string
orthologs is a reference to a list where each element is a fid

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is an orthologs
fid is a string
orthologs is a reference to a list where each element is a fid


=end text



=item Description

fids_to_orthologs takes as input a list of feature ids, and
returns a mapping of each fid to its orthologous fids in
all genomes.

=back

=cut

sub fids_to_orthologs
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_orthologs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_orthologs');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_orthologs

	$return={};
	my $ua = LWP::UserAgent->new;
	my $kbMOT=$self->{kbMOT};

	my $fids2externalIds=$kbMOT->fids_to_moLocusIds($fids);

	# this is not the best way, but should work
	foreach my $fid (keys %$fids2externalIds)
	{
		my $response=$ua->post("http://www.microbesonline.org/cgi-bin/getOrthologs",Content=>{locusId=>$fids2externalIds->{$fid}[0]});
		my $json=from_json($response->content);
		my $moOrthologs=$json->{$fids2externalIds->{$fid}[0]};
		my $moOrthologs2fids=$kbMOT->moLocusIds_to_fids($moOrthologs);

		my %kbOrthologs;
		foreach my $moOrthLocusId (keys %$moOrthologs2fids)
		{
			next unless ref $moOrthologs2fids->{$moOrthLocusId};
			$kbOrthologs{$moOrthologs2fids->{$moOrthLocusId}}=1;
#			push @{$return->{$fid}},@{$moOrthologs2fids->{$moOrthLocusId}};
		}
		my @kbOrthologs=keys %kbOrthologs;
		$return->{$fid} = \@kbOrthologs;
	}

    #END fids_to_orthologs
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_orthologs:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_orthologs');
    }
    return($return);
}




=head2 fids_to_ec

  $return = $obj->fids_to_ec($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is an ec
fid is a string
ec is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is an ec
fid is a string
ec is a reference to a list where each element is a string


=end text



=item Description

fids_to_ec takes as input a list of feature ids, and returns
a mapping of each fid to its Enzyme Commission numbers (EC).

=back

=cut

sub fids_to_ec
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_ec:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_ec');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_ec

	$return={};

	if (scalar @$fids)
	{
#		my $ctxA = ContextAdapter->new($ctx);
#		my $user_token = $ctxA->user_token();

		my $moDbh=$self->{moDbh};
		my $kbMOT=$self->{kbMOT};

		my $fids2externalIds=$kbMOT->fids_to_moLocusIds($fids);

		# this is not the best way, but should work
		foreach my $fid (keys %$fids2externalIds)
		{
			$return->{$fid} = [];
			my $ecSql='SELECT DISTINCT locusId,ecNum FROM Locus2Ec WHERE
				locusId = ?';
#			my $placeholders='?,' x (@{$fids2externalIds->{$fid}});
#			chop $placeholders;
#			$sql.=$placeholders.')';
		
			my $ecSth=$moDbh->prepare($ecSql);
			$ecSth->execute($fids2externalIds->{$fid}[0]);
			while (my $row=$ecSth->fetch)
			{
				push @{$return->{$fid}},$row->[1];
			}

		}
	}
    #END fids_to_ec
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_ec:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_ec');
    }
    return($return);
}




=head2 fids_to_go

  $return = $obj->fids_to_go($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is a go
fid is a string
go is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a fid
$return is a reference to a hash where the key is a fid and the value is a go
fid is a string
go is a reference to a list where each element is a string


=end text



=item Description

fids_to_go takes as input a list of feature ids, and returns
a mapping of each fid to its Gene Ontology assignments (GO).

=back

=cut

sub fids_to_go
{
    my $self = shift;
    my($fids) = @_;

    my @_bad_arguments;
    (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"fids\" (value was \"$fids\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to fids_to_go:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_go');
    }

    my $ctx = $Bio::KBase::ProteinInfoService::Service::CallContext;
    my($return);
    #BEGIN fids_to_go

	$return={};

	if (scalar @$fids)
	{
#		my $ctxA = ContextAdapter->new($ctx);
#		my $user_token = $ctxA->user_token();

		my $moDbh=$self->{moDbh};
		my $kbMOT=$self->{kbMOT};

		my $fids2externalIds=$kbMOT->fids_to_moLocusIds($fids);

		# this is not the best way, but should work
		foreach my $fid (keys %$fids2externalIds)
		{
			my $goSql='SELECT DISTINCT locusId,acc FROM Locus2Go l2g
		       		JOIN term t ON (t.id=l2g.goId)
				WHERE locusId = ?';
#			my $placeholders='?,' x (@{$fids2externalIds->{$fid}});
#			chop $placeholders;
#			$sql.=$placeholders.')';
		
			my $goSth=$moDbh->prepare($goSql);
			$goSth->execute($fids2externalIds->{$fid}[0]);
			while (my $row=$goSth->fetch)
			{
				push @{$return->{$fid}},$row->[1];
			}

		}
	}
    #END fids_to_go
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to fids_to_go:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'fids_to_go');
    }
    return($return);
}




=head2 version 

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
}

=head1 TYPES



=head2 fid

=over 4



=item Description

A fid is a unique identifier of a feature.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 domain_id

=over 4



=item Description

A domain_id is an identifier of a protein domain or family
(e.g., COG593, TIGR00362). Most of these are stable identifiers
that come from external curated libraries, such as COG or InterProScan,
but some may be unstable identifiers that come from automated
analyses like FastBLAST. (The current implementation includes only
COG and InterProScan HMM libraries, such as TIGRFam and Pfam.)


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 domains

=over 4



=item Description

Domains are a list of domain_ids.


=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 ec

=over 4



=item Description

ECs are a list of Enzyme Commission identifiers.


=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 go

=over 4



=item Description

GOs are a list of Gene Ontology identifiers.


=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 ipr

=over 4



=item Description

IPRs are a list of InterPro identifiers.


=item Definition

=begin html

<pre>
a reference to a list where each element is a string
</pre>

=end html

=begin text

a reference to a list where each element is a string

=end text

=back



=head2 operon

=over 4



=item Description

An operon is represented by a list of fids
which make up that operon.


=item Definition

=begin html

<pre>
a reference to a list where each element is a fid
</pre>

=end html

=begin text

a reference to a list where each element is a fid

=end text

=back



=head2 orthologs

=over 4



=item Description

Orthologs are a list of fids which are orthologous to a given fid.


=item Definition

=begin html

<pre>
a reference to a list where each element is a fid
</pre>

=end html

=begin text

a reference to a list where each element is a fid

=end text

=back



=cut

1;
