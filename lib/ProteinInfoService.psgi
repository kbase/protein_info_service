use Bio::KBase::ProteinInfoService::Impl;

use Bio::KBase::ProteinInfoService::Service;



my @dispatch;

{
    my $obj = Bio::KBase::ProteinInfoService::Impl->new;
    push(@dispatch, 'ProteinInfo' => $obj);
}


my $server = Bio::KBase::ProteinInfoService::Service->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler;
