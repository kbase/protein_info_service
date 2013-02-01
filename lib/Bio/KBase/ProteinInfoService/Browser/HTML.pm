package Bio::KBase::ProteinInfoService::Browser::HTML;
require Exporter;

use strict;
use CGI qw(:standard);
use Bio::KBase::ProteinInfoService::Browser::Defaults;

use vars '$VERSION';
use vars qw($defaults);
$VERSION = 0.01;

our @ISA = qw(Exporter);
our @EXPORT = qw(htmlError htmlTemplate htmlLoadTemplate stateHeader);
our $headerDisp = 0;

sub buildOptionList
{
	my $results = shift;
	my $selected = shift;
	my $insertOpts = shift;
	$selected = []
		if ( !defined($selected) );
	$insertOpts = []
		if ( !defined($insertOpts) );

	my %sel = ();
	if ( ref($selected) eq 'ARRAY' )
	{
		foreach my $s ( @{$selected} )
		{
			$sel{$s} = 1;
		}
	} elsif ( !ref($selected) )
	{
		$sel{$selected} = 1;
	}

	my $optionsStr = "";

	foreach my $r ( ( @{$insertOpts}, @{$results} ) )
	{
		my $selText = ( exists( $sel{ $r->{value} } ) ) ?
				" SELECTED" : "";
		$optionsStr .= "<OPTION VALUE=\"$r->{value}\"$selText>$r->{description}</OPTION>\n";
	}

	return $optionsStr;
}

sub stateHeader
{
	if ( $headerDisp == 0 )
	{
		$headerDisp = 1;
		return header;
	}
}

sub htmlError($)
{
	my $error = shift;

	print stateHeader;
	print
		start_html( $defaults->{htmlErrorTitle} ),
		h1( $defaults->{htmlErrorTitle} ),
		p,
		$error,
		p,
		end_html;
}

sub _replace($$\$)
{
	my $macro = shift;
	my $content = shift;
	my $text = shift;

	$$text =~ s/$macro/$content/g;
}

sub htmlLoadTemplate($)
{
	my $file = shift;
	local *IN;

	if ( -e $file )
	{
		open(IN, "<$file");
		my @templateData = <IN>;
		close(IN);

		return join( "", @templateData );
	}

	htmlError( "Missing template '$file'" );
	return "";
}

sub replaceMacros($$;$);
sub replaceMacros($$;$)
{
	my $tmpl = shift;
	my $vals = shift;
	my $errOk = shift;

	$errOk = 1
		if ( !defined($errOk) );

	return $tmpl
		if ( !defined($tmpl) );

	while ( $tmpl =~ /%((?:[a-zA-Z]\w*)|\{(?:[^\}]+)\})/g )
	{
		my $keyName = $1;
		my $replName = $keyName;
		$replName =~ s/([\{\}\(\)\.\+\-\*\/])/\\$1/g;
		$keyName =~ s/[\{\}]+//g;
		my $mods = undef;
		($keyName, $mods) = split(/\s*,\s*/, $keyName, 2);
		$mods = lc($mods);
		my $keyVal = undef;

		if ( $keyName !~ /^\([^\)]+\)$/ )
		{
			$keyVal = exists( $vals->{$keyName} ) ?
				$vals->{$keyName} : undef;
		} else {
			$keyName =~ s/^\(|\)$//g;
			$keyName = replaceMacros( $keyName, $vals );
			$keyVal = eval( $keyName );
		}
		$keyVal = ""
			if ( !defined($keyVal) && $errOk );
		my @mod = split(/\s*,\s*/, $mods);

		# Apply string modifiers
		if ( (scalar( @mod ) > 0) && (length($keyVal) > 0) )
		{
			foreach my $m ( @mod )
			{
				if ( $m eq 'lc' )
				{
					$keyVal = lc($keyVal);
				} elsif ( $m eq 'uc' )
				{
					$keyVal = uc($keyVal);
				} elsif ( $m eq 'ucf' )
				{
					$keyVal = ucfirst($keyVal);
				} elsif ( $m eq 'lcf' )
				{
					$keyVal = lcfirst($keyVal);
				} elsif ( $m eq 'proper' )
				{
					$keyVal =~ s/(['\w]{1,})/ucfirst($1)/ge;
				} elsif ( $m eq 'len' )
				{
					$keyVal = length($keyVal);
				} elsif ( $m =~ /^substr\((\d+)\s*:\s*(\d+)?\)/i )
				{
					my $start = $1;
					my $len = $2;
					if ( defined($len) )
					{
						$keyVal = substr( $keyVal, int($start), int($len) );
					} else {
						$keyVal = substr( $keyVal, int($start) );
					}
				} elsif ( $m =~ /^%/ )
				{
					$keyVal = sprintf( $m, $keyVal )
						if ( $keyVal !~ /^nan$/i );
				}
			}
		}

		if ( defined($keyVal) )
		{
			if ( $replName =~ /^\\\{[^}]+\\\}$/ )
			{
				$tmpl =~ s/%${replName}/$keyVal/ig;
			} else {
				$tmpl =~ s/%${replName}\b/$keyVal/ig;
			}
		}

		pos( $tmpl ) = 0;
	}

	$tmpl =~ s/%%/%/g;
	return $tmpl;
}

sub expandMacros($$);
sub expandMacros($$)
{
	my $tmpl = shift;
	my $vals = shift;

	my $expand = "";
	my $lastPos = 0;
	while ( $tmpl =~ /(%\[(\w+)\s+([^\]]+)\])/gims )
	{
		my $type = $2;
		my $params = $3;
		my $pos = pos($tmpl) - length($1);
		my $blockStart = $1;
		my ($blocks, $endPos) = extractBlockContext( $tmpl, $pos );

		$expand .= replaceMacros( substr( $tmpl, $lastPos, $pos - $lastPos ), $vals )
			if ( $pos > $lastPos );

		if ( $type =~ /^if$/i )
		{
			my $cond = replaceMacros( $params, $vals );
			if ( eval( $cond ) )
			{
				$expand .= replaceMacros( expandMacros( $blocks->[0], $vals ), $vals );
			} elsif ( scalar( @{$blocks} ) > 1 )
			{
				$expand .= replaceMacros( expandMacros( $blocks->[1], $vals ), $vals );
			}
		} elsif ( $type =~ /^foreach$/i )
		{
			my ($cond) = $params =~ /%([a-zA-Z]\w*)/;
			if ( exists( $vals->{$cond} ) &&
				ref( $vals->{$cond} ) &&
				( ref( $vals->{$cond} ) eq 'ARRAY' ) )
			{
				foreach my $e ( @{$vals->{$cond}} )
				{
					my %blockVals = %{$vals};
					foreach my $key ( keys( %{$e} ) )
					{
						$blockVals{$key} = $e->{$key};
					}

					$expand .= replaceMacros( expandMacros( $blocks->[0], \%blockVals ), \%blockVals );
				}
			}
		}

		pos($tmpl) = $endPos;
		$lastPos = $endPos;
	}
	$expand .= replaceMacros( substr( $tmpl, $lastPos ), $vals );

	return $expand;
}

sub extractBlockContext
{
	my $tmpl = shift;
	my $pos = shift;
	my @stack = ();
	my @blocks = ();

	pos($tmpl) = $pos;
	while ( $tmpl =~ /(%\[(\w+)\s*[^\]]*\])[\r\n]?/gims )
	{
		my $tag = $2;
		if ( $tag =~ /^else$/i )
		{
			if ( (scalar(@stack) == 1) && ($stack[-1] =~ /^if$/i) )
			{
				my $block = substr( $tmpl, $pos, pos($tmpl) - $pos );
				$block =~ s/^%\[[^\]]+?\][\r\n]*|%\[[^\]]+?\][\r\n]*$//g;
				push( @blocks, $block );
				$pos = pos($tmpl);
			}
		} elsif ( $tag !~ /^end/ )
		{
			push( @stack, $tag );
		} else
		{
			my $endMatch = $tag;
			$endMatch =~ s/^end//ig;
			if ( $stack[-1] eq $endMatch )
			{
				pop( @stack );
			} else {
				die "error: end of block mismatch; end of $endMatch is matched to $stack[-1]\n";
			}
		}
		if ( scalar(@stack) < 1 )
		{
			last;
		}
	}

	if ( scalar(@stack) < 1 )
	{
		my $block = substr( $tmpl, $pos, pos($tmpl) - $pos );
		$block =~ s/^%\[[^\]]+?\][\r\n]*|%\[[^\]]+?\][\r\n]*$//g;
		push( @blocks, $block );
		return (\@blocks, pos($tmpl));
	} else {
		die "error: unmatched end block tag for ", $stack[-1], "\n";
	}
}

sub htmlTemplate( $;\%$$$$ );
sub htmlTemplate( $;\%$$$$ )
{
	my $file = shift;
	my $vals = shift;
	my $title = shift;
	my $useHeader = shift;
	my $useFooter = shift;
	my $noPrint = shift;
	my $template = "";

	$vals = {}
		if ( !defined( $vals ) );
	$title = $defaults->{htmlTitle}
		if ( !defined( $title ) );
	$useHeader = 0
		if ( !defined( $useHeader ) );
	$useFooter = 0
		if ( !defined( $useFooter ) );

	if ( $useHeader == 1 )
	{
		my %headerVals = ( title => $title );
		$template .= htmlTemplate( $defaults->{htmlHeader}, %headerVals, "", 0, 0, 1 );
	}

	my $tmpl = htmlLoadTemplate( $defaults->{htmlTemplateBase} . $file );

	$tmpl = expandMacros( $tmpl, $vals );

	$template .= $tmpl;

	if ( $useFooter == 1 )
	{
		my %footerVals = ( );
		$template .= htmlTemplate( $defaults->{htmlFooter}, %footerVals, "", 0, 0, 1 );
	}

	if ( !$noPrint )
	{
		print stateHeader;
		print $template;
	}

	return $template;
}

1;
