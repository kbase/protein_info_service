#  Simple module that returns the host and port to use to test the service.  Could be extended to
#  read a config file if more config options are required in the future.
#
#  created Oct 2012 by msneddon
#  update 12/5/2012 - landml

package ProteinTestConfig;

use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(getHost getPort getURL);


# CHANGE THE HOST AND PORT CONFIGURATION HERE
my $host = "http://localhost";
my $port = "7057";
my $URL = "http://kbase.us/services/protein_info_service";

sub getHost  { return $host; }
sub getPort  { return $port; }
sub getURL   { return $URL;  }

1;
