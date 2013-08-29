package Bio::KBase::ProteinInfoService::Client;

use JSON::RPC::Client;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

Bio::KBase::ProteinInfoService::Client

=head1 DESCRIPTION


Given a feature ID that is a protein, the protein info service
returns various annotations such as domain annotations, orthologs
in other genomes, and operons.


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => Bio::KBase::ProteinInfoService::Client::RpcClient->new,
	url => $url,
    };


    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 fids_to_operons

  $return = $obj->fids_to_operons($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.operon
fid is a string
operon is a reference to a list where each element is a ProteinInfo.fid

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.operon
fid is a string
operon is a reference to a list where each element is a ProteinInfo.fid


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
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_operons (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_operons:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_operons');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ProteinInfo.fids_to_operons",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_operons',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_operons",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_operons',
				       );
    }
}



=head2 fids_to_domains

  $return = $obj->fids_to_domains($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.domains
fid is a string
domains is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.domains
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
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_domains (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_domains:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_domains');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ProteinInfo.fids_to_domains",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_domains',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_domains",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_domains',
				       );
    }
}



=head2 fids_to_domain_hits

  $return = $obj->fids_to_domain_hits($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a reference to a list where each element is a ProteinInfo.Hit
fid is a string
Hit is a reference to a hash where the following keys are defined:
	id has a value which is a string
	subject_db has a value which is a string
	description has a value which is a string
	query_begin has a value which is an int
	query_end has a value which is an int
	subject_begin has a value which is an int
	subject_end has a value which is an int
	score has a value which is a float
	evalue has a value which is a float

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a reference to a list where each element is a ProteinInfo.Hit
fid is a string
Hit is a reference to a hash where the following keys are defined:
	id has a value which is a string
	subject_db has a value which is a string
	description has a value which is a string
	query_begin has a value which is an int
	query_end has a value which is an int
	subject_begin has a value which is an int
	subject_end has a value which is an int
	score has a value which is a float
	evalue has a value which is a float


=end text

=item Description

fids_to_domain_hits takes as input a list of feature ids, and
returns a mapping of each fid to a list of hits. (This includes COG,
even though COG is not part of InterProScan.)

=back

=cut

sub fids_to_domain_hits
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_domain_hits (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_domain_hits:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_domain_hits');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ProteinInfo.fids_to_domain_hits",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_domain_hits',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_domain_hits",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_domain_hits',
				       );
    }
}



=head2 domains_to_fids

  $return = $obj->domains_to_fids($domain_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$domain_ids is a ProteinInfo.domains
$return is a reference to a hash where the key is a ProteinInfo.domain_id and the value is a reference to a list where each element is a ProteinInfo.fid
domains is a reference to a list where each element is a string
domain_id is a string
fid is a string

</pre>

=end html

=begin text

$domain_ids is a ProteinInfo.domains
$return is a reference to a hash where the key is a ProteinInfo.domain_id and the value is a reference to a list where each element is a ProteinInfo.fid
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
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function domains_to_fids (received $n, expecting 1)");
    }
    {
	my($domain_ids) = @args;

	my @_bad_arguments;
        (ref($domain_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"domain_ids\" (value was \"$domain_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to domains_to_fids:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'domains_to_fids');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ProteinInfo.domains_to_fids",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'domains_to_fids',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method domains_to_fids",
					    status_line => $self->{client}->status_line,
					    method_name => 'domains_to_fids',
				       );
    }
}



=head2 domains_to_domain_annotations

  $return = $obj->domains_to_domain_annotations($domain_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$domain_ids is a ProteinInfo.domains
$return is a reference to a hash where the key is a ProteinInfo.domain_id and the value is a string
domains is a reference to a list where each element is a string
domain_id is a string

</pre>

=end html

=begin text

$domain_ids is a ProteinInfo.domains
$return is a reference to a hash where the key is a ProteinInfo.domain_id and the value is a string
domains is a reference to a list where each element is a string
domain_id is a string


=end text

=item Description

domains_to_domain_annotations takes as input a list of domain_ids, and
returns a mapping of each domain_id to its text annotation as provided
by its maintainer (usually retrieved from InterProScan, or from NCBI
for COG).

=back

=cut

sub domains_to_domain_annotations
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function domains_to_domain_annotations (received $n, expecting 1)");
    }
    {
	my($domain_ids) = @args;

	my @_bad_arguments;
        (ref($domain_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"domain_ids\" (value was \"$domain_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to domains_to_domain_annotations:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'domains_to_domain_annotations');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ProteinInfo.domains_to_domain_annotations",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'domains_to_domain_annotations',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method domains_to_domain_annotations",
					    status_line => $self->{client}->status_line,
					    method_name => 'domains_to_domain_annotations',
				       );
    }
}



=head2 fids_to_ipr

  $return = $obj->fids_to_ipr($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.ipr
fid is a string
ipr is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.ipr
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
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_ipr (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_ipr:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_ipr');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ProteinInfo.fids_to_ipr",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_ipr',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_ipr",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_ipr',
				       );
    }
}



=head2 fids_to_orthologs

  $return = $obj->fids_to_orthologs($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.orthologs
fid is a string
orthologs is a reference to a list where each element is a ProteinInfo.fid

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.orthologs
fid is a string
orthologs is a reference to a list where each element is a ProteinInfo.fid


=end text

=item Description

fids_to_orthologs takes as input a list of feature ids, and
returns a mapping of each fid to its orthologous fids in
all genomes.

=back

=cut

sub fids_to_orthologs
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_orthologs (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_orthologs:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_orthologs');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ProteinInfo.fids_to_orthologs",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_orthologs',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_orthologs",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_orthologs',
				       );
    }
}



=head2 fids_to_ec

  $return = $obj->fids_to_ec($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.ec
fid is a string
ec is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.ec
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
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_ec (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_ec:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_ec');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ProteinInfo.fids_to_ec",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_ec',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_ec",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_ec',
				       );
    }
}



=head2 fids_to_go

  $return = $obj->fids_to_go($fids)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.go
fid is a string
go is a reference to a list where each element is a string

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a ProteinInfo.go
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
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fids_to_go (received $n, expecting 1)");
    }
    {
	my($fids) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fids_to_go:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fids_to_go');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ProteinInfo.fids_to_go",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fids_to_go',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fids_to_go",
					    status_line => $self->{client}->status_line,
					    method_name => 'fids_to_go',
				       );
    }
}



=head2 fid_to_neighbors

  $return = $obj->fid_to_neighbors($id, $thresh)

=over 4

=item Parameter and return types

=begin html

<pre>
$id is a ProteinInfo.fid
$thresh is a ProteinInfo.neighbor_threshold
$return is a ProteinInfo.neighbor
fid is a string
neighbor_threshold is a float
neighbor is a reference to a hash where the key is a ProteinInfo.fid and the value is a float

</pre>

=end html

=begin text

$id is a ProteinInfo.fid
$thresh is a ProteinInfo.neighbor_threshold
$return is a ProteinInfo.neighbor
fid is a string
neighbor_threshold is a float
neighbor is a reference to a hash where the key is a ProteinInfo.fid and the value is a float


=end text

=item Description

fid_to_neighbor takes as input a single feature id, and
a neighbor score threshold and returns a list of neighbors
where neighbor score >= threshold

=back

=cut

sub fid_to_neighbors
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fid_to_neighbors (received $n, expecting 2)");
    }
    {
	my($id, $thresh) = @args;

	my @_bad_arguments;
        (!ref($id)) or push(@_bad_arguments, "Invalid type for argument 1 \"id\" (value was \"$id\")");
        (!ref($thresh)) or push(@_bad_arguments, "Invalid type for argument 2 \"thresh\" (value was \"$thresh\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fid_to_neighbors:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fid_to_neighbors');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ProteinInfo.fid_to_neighbors",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fid_to_neighbors',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fid_to_neighbors",
					    status_line => $self->{client}->status_line,
					    method_name => 'fid_to_neighbors',
				       );
    }
}



=head2 fidlist_to_neighbors

  $return = $obj->fidlist_to_neighbors($fids, $thresh)

=over 4

=item Parameter and return types

=begin html

<pre>
$fids is a reference to a list where each element is a ProteinInfo.fid
$thresh is a ProteinInfo.neighbor_threshold
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a reference to a list where each element is a ProteinInfo.neighbor
fid is a string
neighbor_threshold is a float
neighbor is a reference to a hash where the key is a ProteinInfo.fid and the value is a float

</pre>

=end html

=begin text

$fids is a reference to a list where each element is a ProteinInfo.fid
$thresh is a ProteinInfo.neighbor_threshold
$return is a reference to a hash where the key is a ProteinInfo.fid and the value is a reference to a list where each element is a ProteinInfo.neighbor
fid is a string
neighbor_threshold is a float
neighbor is a reference to a hash where the key is a ProteinInfo.fid and the value is a float


=end text

=item Description

fidlist_to_neighbors takes as input a list of feature ids, and
a minimal neighbor score, and returns a mapping of each fid to
its neighbors, based on neighbor score >= threshold

=back

=cut

sub fidlist_to_neighbors
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function fidlist_to_neighbors (received $n, expecting 2)");
    }
    {
	my($fids, $thresh) = @args;

	my @_bad_arguments;
        (ref($fids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"fids\" (value was \"$fids\")");
        (!ref($thresh)) or push(@_bad_arguments, "Invalid type for argument 2 \"thresh\" (value was \"$thresh\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to fidlist_to_neighbors:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'fidlist_to_neighbors');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ProteinInfo.fidlist_to_neighbors",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'fidlist_to_neighbors',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method fidlist_to_neighbors",
					    status_line => $self->{client}->status_line,
					    method_name => 'fidlist_to_neighbors',
				       );
    }
}



sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, {
        method => "ProteinInfo.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'fidlist_to_neighbors',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method fidlist_to_neighbors",
            status_line => $self->{client}->status_line,
            method_name => 'fidlist_to_neighbors',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for Bio::KBase::ProteinInfoService::Client\n";
    }
    if ($sMajor == 0) {
        warn "Bio::KBase::ProteinInfoService::Client version is $svr_version. API subject to change.\n";
    }
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



=head2 neighbor_threshold

=over 4



=item Description

A neighbor_threshold is a floating point number indicating a bound
for the neighbor score


=item Definition

=begin html

<pre>
a float
</pre>

=end html

=begin text

a float

=end text

=back



=head2 neighbor

=over 4



=item Description

Neighbor is a hash of fids to a neighbor score


=item Definition

=begin html

<pre>
a reference to a hash where the key is a ProteinInfo.fid and the value is a float
</pre>

=end html

=begin text

a reference to a hash where the key is a ProteinInfo.fid and the value is a float

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



=head2 Hit

=over 4



=item Description

A Hit is a description of a match to another object (a fid,
a gene family, an HMM).  It is a structure with the following
fields:
        id: the common identifier of the object (e.g., a fid, an HMM accession)
        subject_db: the source database of the original hit (e.g., KBase for fids, TIGRFam, Pfam, COG)
        description: a human-readable textual description of the object (might be empty)
        query_begin: the start of the hit in the input gene sequence
        query_end: the end of the hit in the input gene sequence
        subject_begin: the start of the hit in the object gene sequence
        subject_end: the end of the hit in the object gene sequence
        score: the score (if provided) of the hit to the object
        evalue: the evalue (if provided) of the hit to the object


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a string
subject_db has a value which is a string
description has a value which is a string
query_begin has a value which is an int
query_end has a value which is an int
subject_begin has a value which is an int
subject_end has a value which is an int
score has a value which is a float
evalue has a value which is a float

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a string
subject_db has a value which is a string
description has a value which is a string
query_begin has a value which is an int
query_end has a value which is an int
subject_begin has a value which is an int
subject_end has a value which is an int
score has a value which is a float
evalue has a value which is a float


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
which make up that operon.  The order within the list is not
defined; the fids_to_locations method can report on the
order of the fids in the operon.


=item Definition

=begin html

<pre>
a reference to a list where each element is a ProteinInfo.fid
</pre>

=end html

=begin text

a reference to a list where each element is a ProteinInfo.fid

=end text

=back



=head2 orthologs

=over 4



=item Description

Orthologs are a list of fids which are orthologous to a given fid.


=item Definition

=begin html

<pre>
a reference to a list where each element is a ProteinInfo.fid
</pre>

=end html

=begin text

a reference to a list where each element is a ProteinInfo.fid

=end text

=back



=cut

package Bio::KBase::ProteinInfoService::Client::RpcClient;
use base 'JSON::RPC::Client';

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $obj) = @_;
    my $result;

    if ($uri =~ /\?/) {
       $result = $self->_get($uri);
    }
    else {
        Carp::croak "not hashref." unless (ref $obj eq 'HASH');
        $result = $self->_post($uri, $obj);
    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
