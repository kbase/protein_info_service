package Bio::KBase::ProteinInfoService::Browser::Defaults;
require Exporter;

#use GD;
use strict;

# almost any use of CGI breaks motifscan (?!?)
#use CGI qw/url/;
#my $cgi = CGI->new;

our @ISA = qw(Exporter);
our $defaults = {};
our $jobStatus = {};
our $jobStatusName = [];
our $motifTools = [];
our $motifToScan = {};
our $msaTrimTypes = [];
our $treeTools = [];
our $treeToolsId = {};

# Job Status Values
$jobStatus->{SUBMITTED}			= 0;
$jobStatus->{QUEUED}			= 1;
$jobStatus->{RUNNING}			= 2;
$jobStatus->{DONE}			= 3;
$jobStatus->{FAIL}			= 4;
$jobStatus->{DELETE}			= 5;
$jobStatus->{KILLED}			= 6;
$jobStatusName->[0]			= "SUBMITTED";
$jobStatusName->[1]			= "QUEUED";
$jobStatusName->[2]			= "RUNNING";
$jobStatusName->[3]			= "DONE";
$jobStatusName->[4]			= "FAIL";
$jobStatusName->[5]			= "DELETE";
$jobStatusName->[6]			= "KILLED";

# Motif Tools
$motifTools->[0]			= "AlignACE";
$motifTools->[1]			= "MEME";
$motifTools->[2]			= "Weeder";
$motifToScan->{ALIGNACE}		= "ScanACE";
$motifToScan->{MEME}			= "Patser";
$motifToScan->{WEEDER}			= "Patser";
$motifToScan->{upload}			= "Patser";

# Tree Tools
$treeTools->[0]                         = "Tree-Puzzle";
$treeTools->[1]                         = "PhyML";
$treeTools->[2]                         = "Neighbor";
$treeTools->[3]                         = "FastTree";
$treeTools->[4]                         = "RAxML";
$treeTools->[255]			= "Uploaded";
$treeToolsId->{'TREE-PUZZLE'}           = 0;
$treeToolsId->{'PHYML'}                 = 1;
$treeToolsId->{'NEIGHBOR'}              = 2;
$treeToolsId->{'FASTTREE'}              = 3;
$treeToolsId->{'RAXML'}                 = 4;
$treeToolsId->{'UPLOAD'}		= 255;

# MSA Trim Types
$msaTrimTypes->[0]			= "Raw";
$msaTrimTypes->[1]			= "Trimmed";
$msaTrimTypes->[2]			= "Gblocks";

#
# Default Values
#
# Could also set showMeta manually
#$defaults->{showMeta} = 0;
#$defaults->{showMeta} = ($cgi->url() =~ /^http:\/\/dylan/) ? 1 : undef;
$defaults->{showMeta} = (defined $ENV{SERVER_NAME} && $ENV{SERVER_NAME} =~ /^meta/) ? 1 : 0;

$defaults->{mode}			= 0;
$defaults->{range}			= 20000;

# uncomment this to put a MOTD on every page with the genome selector template
$defaults->{motd}		        = ($defaults->{showMeta}) 
    ? 'metaMicrobesOnline is brand new, and offers somewhat different functionality from <a href="http://www.microbesonline.org">isolate-only MicrobesOnline</a>.  Please alert us to any issues at <a href="mailto:help@microbesonline.org">help@microbesonline.org</a>.' 
    : undef;

$defaults->{sendmail}			= "/usr/sbin/sendmail -bm -t";

$defaults->{adminEmail}			= "help\@microbesonline.org";

$defaults->{webHost}			= $ENV{SERVER_NAME};
$defaults->{webHost}			.= ":$ENV{SERVER_PORT}"
	if ( exists($ENV{SERVER_PORT}) &&
		(length($ENV{SERVER_PORT}) > 0) &&
		($ENV{SERVER_PORT} ne '80') );
#$defaults->{dbHost}			= "localhost";
$defaults->{dbHost}			= "140.221.84.194";
#$defaults->{dbDatabase}			= ($defaults->{showMeta}) ? "meta2010jul" : "genomics_test";
$defaults->{dbDatabase}			= "genomics_dev";
$defaults->{dbUser}			= "genomics";
$defaults->{dbPassword}			= undef;
$defaults->{dbType}			= "mysql";

$defaults->{cookieExpire}		= "+12h";
$defaults->{userTrackingCookieExpire}	= "+365d";
$defaults->{cookieDomain}               = $ENV{SERVER_NAME};
$defaults->{cookieDomain}               = ".microbesonline.org"
	if ( exists($ENV{SERVER_NAME}) &&
		( $ENV{SERVER_NAME} =~ /microbesonline\.org/ ) );

$defaults->{baseDir}			= "$ENV{SANDBOX_DIR}/Genomics/browser/";
$defaults->{htmlTemplateBase}		= $defaults->{baseDir} . "templates/";
$defaults->{htmlFooter}			= "footer.tmpl";
$defaults->{htmlHeader}			= ($defaults->{showMeta}) ? "header_meta.tmpl" : "header.tmpl";

$defaults->{htmlTmpDir}			= "$ENV{SANDBOX_DIR}/Genomics/html/" . "tmp/";
$defaults->{htmlTmpUri}			= "/tmp/";
$defaults->{jsUri}			= "/js/";
$defaults->{cgiUri}			= "/cgi-bin/";
$defaults->{uaParseFile}		= "$ENV{SANDBOX_DIR}/Genomics/browser/config/uaparse.txt";

# KEGG::Map API
$defaults->{keggMapDir}			= "$ENV{SANDBOX_DIR}/Genomics/html/kegg";
$defaults->{keggMapHighlightColor}	= [250, 160, 160];
$defaults->{keggMapLegend}		= {};
$defaults->{keggMapLegend}->{font} 	= "gdSmallFont";
$defaults->{keggMapLegend}->{buffer} = "5";
$defaults->{keggMapLegend}->{numColumns} = "3";
$defaults->{keggMapLegend}->{labelPad}	= "15";
$defaults->{keggMapLegend}->{textColor}	= [0, 0, 0];
$defaults->{keggMapLegend}->{enzyme}	= {};
$defaults->{keggMapLegend}->{enzyme}->{shape}	= "rect";
$defaults->{keggMapLegend}->{enzyme}->{width}	= "10";
$defaults->{keggMapLegend}->{enzyme}->{height}	= "10";
$defaults->{keggMapLegend}->{compound}->{shape}	= "circ";
$defaults->{keggMapLegend}->{compound}->{radius} = "5";

# Memcached params
$defaults->{memcachedServers}		= [
						'127.0.0.1:11211',
					  ];
$defaults->{memcachedCompressThreshold}	= 65536;	# 64K
$defaults->{memcachedDebug}		= 0;		# set to 1 for debugging data; slows performance

#
# If you have a web cluster, the following directory must be the same
# physical disk for all machines.  You can accomplish this with NFS.
#
$defaults->{sharedJobDir}		= "$ENV{SANDBOX_DIR}/Genomics/html/" . "jobdata/";
$defaults->{sharedJobUri}		= "/jobdata/";
$defaults->{jobTmpDir}			= "/tmp/";
$defaults->{microArrayDir}		= "$ENV{SANDBOX_DIR}/Genomics/html/" . "microarray/";
$defaults->{webLogoBaseDir}		= $defaults->{baseDir} . "lib/";

$defaults->{sessionDir}			= $defaults->{baseDir} . "sessions/";
$defaults->{sessionMaxSeqs}		= 500;
$defaults->{sessionMaxCarts}		= 50;
$defaults->{sessionTmpDir}		= "/tmp/";
$defaults->{sessionDbHost}		= "localhost";
$defaults->{sessionDbDatabase}		= ($defaults->{showMeta}) ? "meta2010jul" : "genomics_test";
$defaults->{sessionDbUser}		= "cart";
$defaults->{sessionDbPassword}		= "cart";
$defaults->{sessionDbType}		= "mysql";

$defaults->{maxJobRunTime}		= 60;	# minutes
$defaults->{maxConcurrentJobsPerUser}	= 1;
$defaults->{treeAAModel}		= "JTT";
$defaults->{treeNAModel}		= "HKY";
$defaults->{fasttreeAAModel}		= "JTT+CAT";
$defaults->{fasttreeNAModel}		= "GTR+CAT";

$defaults->{binDir}			= $defaults->{baseDir} . "bin/";
$defaults->{ALIGNACE}			= $defaults->{binDir} . "AlignACE";
$defaults->{BL2SEQ}			= $defaults->{binDir} . "bl2seq";
$defaults->{BLASTALL}			= $defaults->{binDir} . "blastall";
$defaults->{CLUSTALW}			= $defaults->{binDir} . "clustalw";
$defaults->{COMBINELENGTHBOOTSTRAP}	= $defaults->{binDir} . "combineLengthBootstrap.pl";
$defaults->{CONSENSE}			= $defaults->{binDir} . "consense";
$defaults->{CP}				= "/bin/cp";
$defaults->{SEQBOOT}			= $defaults->{binDir} . "seqboot";
$defaults->{PROTDIST}			= $defaults->{binDir} . "protdist";
$defaults->{DNADIST}			= $defaults->{binDir} . "dnadist";
$defaults->{DOMSEARCH}			= $defaults->{binDir} . "DomSearch";
$defaults->{FASTACMD}			= $defaults->{binDir} . "fastacmd";
$defaults->{FORMATDB}			= $defaults->{binDir} . "formatdb";
$defaults->{GBLOCKS}			= $defaults->{binDir} . "Gblocks";
$defaults->{GFCLIENT}			= $defaults->{binDir} . "gfClient";
$defaults->{HMMSEARCH}			= $defaults->{binDir} . "hmmsearch";
$defaults->{JAVA}			= "/usr/local/java/bin/java";
$defaults->{LS}				= "/bin/ls";
$defaults->{MEGABLAST}			= $defaults->{binDir} . "megablast";
$defaults->{MEME}			= $defaults->{binDir} . "meme.bin";
$defaults->{MOTIFSCAN}			= $defaults->{binDir} . "motifScan";
$defaults->{MUSCLE}			= $defaults->{binDir} . "muscle";
$defaults->{NEIGHBOR}			= $defaults->{binDir} . "neighbor";
$defaults->{PATSER}			= $defaults->{binDir} . "patser";
$defaults->{PATSER_BIN}			= $defaults->{binDir} . "patser-v3b";
$defaults->{PHYML}			= $defaults->{binDir} . "phyml";
$defaults->{PHYML_ALRT}			= $defaults->{binDir} . "phyml_alrt";
$defaults->{PROTDIST}			= $defaults->{binDir} . "protdist";
$defaults->{PUZZLE}			= $defaults->{binDir} . "puzzle";
$defaults->{RETREE}			= $defaults->{binDir} . "retree";
$defaults->{SCANACE}			= $defaults->{binDir} . "ScanACE";
$defaults->{SEQBOOT}			= $defaults->{binDir} . "seqboot";
$defaults->{TREENEIGHBOR}		= $defaults->{binDir} . "treeNeighbor";
$defaults->{TREEPHYML}			= $defaults->{binDir} . "treePhyml";
$defaults->{TREEPUZZLE}			= $defaults->{binDir} . "treePuzzle";
$defaults->{FASTTREE}                   = $defaults->{binDir} . "treeFastTree";
$defaults->{RAXML}                      = $defaults->{binDir} . "treeRAxML";
$defaults->{UNZIP}			= "/usr/bin/unzip";
$defaults->{WEEDER}			= $defaults->{binDir} . "weeder";
$defaults->{WEEDER_TFBS}		= $defaults->{binDir} . "weederTFBS.out";
$defaults->{WEEDER_ADVISER}		= $defaults->{binDir} . "adviser.out";

$defaults->{MEME_DATA_DIR}		= $defaults->{binDir} . "meme_3.5.0";
$defaults->{WEEDER_DATA_DIR}		= $defaults->{binDir};

$defaults->{motifTools}			= $motifTools;
$defaults->{motifToScan}		= $motifToScan;

#Motif-Finding Settings
$defaults->{scaffoldsFasta}		= $defaults->{baseDir} . "fasta/scaffolds_short.fna";

$defaults->{defaultTreeWidth}		= 944;

# BLAT settings
$defaults->{transBlatServer} = 'localhost';
$defaults->{transBlatPort} = [1271,1272,1273,1274,1275,1276];
$defaults->{transBlatPath} = "/";

# FastHMM/FastBLAST settings
# (assume input file is here)
$defaults->{FastBLASTDataDir}			=	"$ENV{SANDBOX_DIR}/Genomics/data/fastblast";
$defaults->{FastBLASTInputFile}			=	$defaults->{FastBLASTDataDir} . '/allProteomes.faa';

# KinoSearch settings
$defaults->{KinoSearchDir}			=	"$ENV{SANDBOX_DIR}/Genomics/data/kinosearch/";

#
# Browser Settings
#
$defaults->{minBrowserWidth}		= 600;		# Pixels
$defaults->{setSpacing}			= 50;		# Pixels
$defaults->{coordClipping}		= 1;		# Disable out of range coordinates?
$defaults->{strandLock}			= 0;		# Enable strand locking for anchored mode
$defaults->{neighborColor}		= 0;		# Use default per-track coloring scheme
$defaults->{neighborGreySingle}		= 1;		# Loci with no orthologs on the current display
							# should be grey instead of having a unique color
$defaults->{dynamicMaxIterations}	= 2;		# In dynamic mode, maximum number of iterations to find an ortholog
$defaults->{maxLocusBatching}		= 500;		# Group loci to speed iterative queries
$defaults->{cogColorThresh}		= 7000;	# Views > this will use the COG table for neighbor coloring
$defaults->{dynamicSetRange}		= 5000;		# Default range around dynamic set loci in bp
$defaults->{scaffoldLenThresh}		= 400000;	# Scaffolds less than this will not be listed in drop-down box
$defaults->{neighborGreyColor}		= "lightgrey";
$defaults->{gapLabelColor}		= "black";
$defaults->{clickAction}		= 0;		# The default action when clicking on feature
							#   0 - load protein page
							#   1 - recenter around feature
							#   2 - add feature to cart

$defaults->{width}			= 800;		# Pixels
$defaults->{bgColor}			= "#FFFFFF";	# Background color
$defaults->{grid}			= 1;		# Enable grid
$defaults->{gridColor}			= "#DCDCFF";	# Grid color
$defaults->{keys}			= 1;		# Enable keys
$defaults->{keyLocation}		= "between";	# Key location
$defaults->{keyAlign}			= "left";	# Key alignment for "between"
$defaults->{keyFont}			= "gdSmallFont";# Font size
$defaults->{keyBottomColor}		= "#EFEFEF";	# Bottom key color
$defaults->{padTop}			= 0;		# Top padding
$defaults->{padLeft}			= 10;		# Left padding
$defaults->{padRight}			= 10;		# Right padding
$defaults->{padBottom}			= 0;		# Bottom padding
$defaults->{scale}			= 1;		# Enable scale
$defaults->{scaleLabel}			= "Scale";	# Scale label
$defaults->{emptyTrack}			= "suppress";	# Suppress empty tracks (key, line, dashed)
$defaults->{svg}			= 0;		# Export to SVG?

# Feature-specific options
$defaults->{labels}			= 1;		# Enable feature labels
$defaults->{labelFont}			= "gdTinyFont";	# Font size
$defaults->{labelLocation}		= "top";	# Label location relative to feature
$defaults->{labelColWidth}		= 100;		# If labels are on the left/right, this is the column width for the labels
$defaults->{labelColor}			= "#000000";	# Feature label color
$defaults->{labelHighlightColor}	= "#00AA00";	# Highlight label color
$defaults->{height}			= 10;		# Feature height

# Microarray::Heatmap defaults
$defaults->{heatmap}			= {};
$defaults->{heatmap}->{cellWidth}	= 20;		# Width of heatmap cell
$defaults->{heatmap}->{cellHeight}	= 12;		# Height of heatmap cell
$defaults->{heatmap}->{scaleCellWidth}	= 20;		# Width of heatmap scale cell
$defaults->{heatmap}->{scaleCellHeight}	= 12;		# Height of heatmap scale cell
$defaults->{heatmap}->{zWidth}		= 2;		# width of z border on cells if enabled (in pixels)
$defaults->{heatmap}->{bgColor}		= [255,255,255];# background color
$defaults->{heatmap}->{zeroColor}	= [255,255,255];# color to use when there is no change
$defaults->{heatmap}->{dataUpColor}	= [0,153,0];	# up-regulated threshold color
$defaults->{heatmap}->{dataDnColor}	= [204,0,0];	# down-regulated threshold color
$defaults->{heatmap}->{zUpColor}	= [255,255,0];	# z value up threshold color
$defaults->{heatmap}->{zDnColor}	= [0,0,255];	# z value down threshold color
$defaults->{heatmap}->{dataScaleMethod}	= 0;		# method for determining scale:
							# 0 - fixed range + fixed threshold steps
							# 1 - fixed range + fixed # of bins
							# 2 - fixed range + continuous
							# 3 - dynamic range + fixed threshold steps
							# 4 - dynamic range + fixed # of bins
							# 5 - dynamic range + continuous (no bins)
$defaults->{heatmap}->{zScaleMethod}	= 3;		# method for determining z scale:
							# 0 - fixed range + fixed threshold steps
							# 1 - fixed range + fixed # of bins
							# 2 - fixed range + continuous
							# 3 - dynamic range + fixed threshold steps
							# 4 - dynamic range + fixed # of bins
							# 5 - dynamic range + continuous (no bins)
$defaults->{heatmap}->{continuousScaleHeight} = 170;	# height of scale if using continous scale
$defaults->{heatmap}->{continuousNumMarkers} = 9;	# number of markers to display if using a
							# continuous scale (should be odd as well)
$defaults->{heatmap}->{dataUpThresh}	= 2.0;		# maximum up-regulated threshold
$defaults->{heatmap}->{dataDnThresh}	= -2.0;		# minimum down-regularted threshold
$defaults->{heatmap}->{dataThreshStep}	= 0.25;		# use 0.25 steps - used in methods 0,2
$defaults->{heatmap}->{dataThreshBins}	= 17;		# use 17 bins - used in method 3 (should be odd)
							# if not odd, the value will be incremented
$defaults->{heatmap}->{zUpThresh}	= 16.0;		# max z score threshold
$defaults->{heatmap}->{zDnThresh}	= -16.0;	# min z score threshold
$defaults->{heatmap}->{zThreshStep}	= 2.0;		# use 2.0 steps - used in methods 0,2
$defaults->{heatmap}->{zThreshBins}	= 17;		# use 17 bins - used in method 3 (should be odd)
							# if not odd, the value will be incremented
$defaults->{heatmap}->{showGrid}	= 1;		# display a grid between and around cells?
$defaults->{heatmap}->{gridColor}	= [0,0,0];	# grid color
$defaults->{heatmap}->{naColor}		= [63,63,63];	# color to use when there's no data
$defaults->{heatmap}->{columnIdOrientation}	= 1;	# how should the header text be rendered?
							# 0 - left diagonally (not supported yet)
							# 1 - upright
							# 2 - right diagonally (not supported yet)
$defaults->{heatmap}->{showRowGroups}	= 1;		# should row groups be shown?
							# 0 - never show row groups
							# 1 - auto-detect (displayed if groups present)
							# 2 - always show row groups
$defaults->{heatmap}->{showRowGroupBrackets}	= 1;	# show row group brackets?
							# 0 - no
							# 1 - yes
$defaults->{heatmap}->{rowGroupIdOrientation}	= 0;	# how are row group labels rendered?
							# 0 - horizontally (default)
							# 1 - vertically
$defaults->{heatmap}->{rowGroupSpacing}	= 10;		# add spacing between adjacent groups?
							# 0 - no
							# >=1 = number of pixels
$defaults->{heatmap}->{showColGroups}	= 1;		# should column groups be shown?
							# 0 - never show column groups
							# 1 - auto-detect (displayed if groups present)
							# 2 - always show column groups
$defaults->{heatmap}->{showColGroupBrackets}	= 1;	# show column group brackets?
							# 0 - no
							# 1 - yes
$defaults->{heatmap}->{columnGroupIdOrientation} = 0;	# how are column group labels rendered?
							# 0 - horizontally (default)
							# 1 - vertically
$defaults->{heatmap}->{colGroupSpacing}	= 10;		# add spacing between adjacent groups?
							# 0 - no
							# >=1 - number of pixels
$defaults->{heatmap}->{showRowDescs}	= 3;		# how row descriptions should be shown
							# 0 - not shown, no mouseovers
							# 1 - mouseovers only
							# 2 - right description box
							# 3 - mouseover + right description box
$defaults->{heatmap}->{showColDescs}	= 1;		# how column descriptions should be shown
							# 0 - not shown, no mouseovers
							# 1 - mouseovers only
$defaults->{heatmap}->{showZScores}	= 1;		# should z scores be shown if present?
							# 0 - not shown, even if present
							# 1 - shown if present
$defaults->{heatmap}->{showScales}	= 1;		# should scale bars be shown?
							# 0 - not shown
							# 1 - shown, z is shown if scores present && showZScores == 1
							# 2 - only data scale is shown (even if z present)
$defaults->{heatmap}->{scaleSpacing}	= 10;		# vertical spacing between scales (pixels)
$defaults->{heatmap}->{scaleLabelSpacing} = 4;		# vertical spacing between label and scale bar (pixels)
$defaults->{heatmap}->{font}		= "gdSmallFont";
$defaults->{heatmap}->{textColor}	= [0,0,0];	# text color
$defaults->{heatmap}->{url}		= {};
$defaults->{heatmap}->{url}->{experiments}	= "/cgi-bin/microarray/reportSet.cgi?id=%id";
$defaults->{heatmap}->{url}->{genes}		= "/cgi-bin/fetchLocus.cgi?locus=%id";
$defaults->{heatmap}->{url}->{experimentsGroup}	= "/cgi-bin/microarray/reportGenes.cgi?locusId=%groupIds&expId=%expId&z=2";
$defaults->{heatmap}->{url}->{genesGroup}	= "/cgi-bin/fetchLoci.cgi?locus=%groupIds";
$defaults->{heatmap}->{url}->{data}		= "#";
$defaults->{heatmap}->{popup}->{experiments}	= "%id %stress %updated %created %source %type group:[%groupId,%groupDesc]";
$defaults->{heatmap}->{popup}->{genes}		= "%id %name %genome group:[%groupId,%groupDesc]";
$defaults->{heatmap}->{popup}->{experimentsGroup} = "[%groupIds]";
$defaults->{heatmap}->{popup}->{genesGroup}	= "[%groupIds]";
$defaults->{heatmap}->{popup}->{data}		= "%stress %id_col %id_row %name %created %data %z ROW:[%groupDesc_row] COL:[%groupDesc_col]";
$defaults->{heatmap}->{rowDesc}->{experiments}	= "%stress %updated %created %source %type";
$defaults->{heatmap}->{rowDesc}->{genes}	= "%id %name %genome";
$defaults->{heatmap}->{label}->{genes}		= "%name";
$defaults->{heatmap}->{label}->{experiments}	= "e%id";
$defaults->{heatmap}->{label}->{scaleData}	= "Data";
$defaults->{heatmap}->{label}->{scaleZ}		= "Z-Score";
$defaults->{heatmap}->{label}->{scaleNoData}	= "No Data";
$defaults->{heatmap}->{label}->{markers}	= "%.2f";
$defaults->{heatmap}->{padding}		= {};
$defaults->{heatmap}->{padding}->{colIdsTop}	= 2;
$defaults->{heatmap}->{padding}->{restTop}	= 8;
$defaults->{heatmap}->{padding}->{rowIdsLeft}	= 2;
$defaults->{heatmap}->{padding}->{dataLeft}	= 8;
$defaults->{heatmap}->{padding}->{rowDescsLeft}	= 8;
$defaults->{heatmap}->{padding}->{scalesLeft}	= 20;

#
# Default Strings
#
$defaults->{htmlTitle}			= "Generic Default Title";
$defaults->{htmlErrorTitle}		= "An Error Has Occured";
$defaults->{htmlDefaultError}		= "Unknown Error";
$defaults->{resetPasswordEmailSubject}	= "VIMSS Account Password Reset";

#
#  Allow Custom Expression Operations
#

$defaults->{customExpressionOperations}	= 0;



#
# Track Colors
#
our $trackColors =	[
                                'darkcyan',
                                'midnightblue',
                                'sandybrown',
                                'mediumturquoise',
                                'chocolate',
                                'indigo',
                                'yellow',
                                'whitesmoke',
                                'aliceblue',
                                'purple',
                                'mediumslateblue',
                                'firebrick',
                                'plum',
                                'silver',
                                'lightblue',
                                'darkgoldenrod',
                                'deeppink',
                                'royalblue',
                                'lightseagreen',
                                'lightslategray',
                                'darkslateblue',
                                'powderblue',
                                'peachpuff',
                                'orchid',
                                'darkkhaki',
                                'darkgreen',
                                'cornsilk',
                                'seashell',
                                'darkblue',
                                'hotpink',
                                'blanchedalmond',
                                'darksalmon',
                                'blue',
                                'mediumvioletred',
                                'lemonchiffon',
                                'snow',
                                'fuchsia',
                                'lightskyblue',
                                'gainsboro',
                                'chartreuse',
                                'darkviolet',
                                'linen',
                                'lightcoral',
                                'moccasin',
                                'teal',
                                'tan',
                                'seagreen',
                                'ghostwhite',
                                'cornflowerblue',
                                'mintcream',
                                'palegreen',
                                'palevioletred',
                                'lightgreen',
                                'lightsalmon',
                                'coral',
                                'gray',
                                'olive',
                                'darkturquoise',
                                'mediumaquamarine',
                                'azure',
                                'cyan',
                                'lightpink',
                                'saddlebrown',
                                'red',
                                'indianred',
                                'peru',
                                'palegoldenrod',
                                'lightcyan',
                                'ivory',
                                'papayawhip',
                                'turquoise',
                                'paleturquoise',
                                'mediumblue',
                                'violet',
                                'lawngreen',
                                'darkorchid',
                                'beige',
                                'tomato',
                                'springgreen',
                                'oldlace',
                                'magenta',
                                'antiquewhite',
                                'floralwhite',
                                'mediumorchid',
                                'orange',
                                'lavender',
                                'darkslategray',
                                'steelblue',
                                'darkred',
                                'blueviolet',
                                'lightgrey',
                                'slateblue',
                                'olivedrab',
                                'sienna',
                                'brown',
                                'green',
                                'forestgreen',
                                'goldenrod',
                                'lightgoldenrodyellow',
                                'mediumspringgreen',
                                'cadetblue',
                                'orangered',
                                'crimson',
                                'lavenderblush',
                                'gold',
                                'darkmagenta',
                                'honeydew',
                                'wheat',
                                'deepskyblue',
                                'dimgray',
                                'slategray',
                                'khaki',
                                'aqua',
                                'aquamarine',
                                'lightsteelblue',
                                'darkolivegreen',
                                'dodgerblue',
                                'darkorange',
                                'darkgray',
                                'bisque',
                                'mediumseagreen',
                                'skyblue',
                                'darkseagreen',
                                'lime',
                                'rosybrown',
                                'greenyellow',
                                'navajowhite',
                                'burlywood',
                                'pink',
                                'maroon',
                                'navy',
                                'lightyellow',
                                'thistle',
                                'limegreen',
                                'mediumpurple',
                                'mistyrose',
                                'salmon',
                                'yellowgreen',
			];

#
# Non grey-scale colors
#
our $trackNoGreyColors =
			[
                                'darkcyan',
                                'midnightblue',
                                'sandybrown',
                                'mediumturquoise',
                                'chocolate',
                                'indigo',
                                'purple',
                                'mediumslateblue',
                                'firebrick',
                                'plum',
                                'lightblue',
                                'darkgoldenrod',
                                'deeppink',
                                'royalblue',
                                'lightseagreen',
                                'darkslateblue',
                                'powderblue',
                                'peachpuff',
                                'orchid',
                                'darkkhaki',
                                'darkgreen',
                                'cornsilk',
                                'seashell',
                                'darkblue',
                                'hotpink',
                                'blanchedalmond',
                                'darksalmon',
                                'blue',
                                'mediumvioletred',
                                'lemonchiffon',
                                'fuchsia',
                                'lightskyblue',
                                'gainsboro',
                                'chartreuse',
                                'darkviolet',
                                'linen',
                                'lightcoral',
                                'moccasin',
                                'teal',
                                'tan',
                                'seagreen',
                                'cornflowerblue',
                                'mintcream',
                                'palegreen',
                                'palevioletred',
                                'lightgreen',
                                'yellow',
                                'lightsalmon',
                                'coral',
                                'olive',
                                'darkturquoise',
                                'mediumaquamarine',
                                'azure',
                                'cyan',
                                'lightpink',
                                'saddlebrown',
                                'red',
                                'indianred',
                                'peru',
                                'palegoldenrod',
                                'lightcyan',
                                'papayawhip',
                                'turquoise',
                                'paleturquoise',
                                'mediumblue',
                                'violet',
                                'lawngreen',
                                'darkorchid',
                                'beige',
                                'tomato',
                                'springgreen',
                                'oldlace',
                                'magenta',
                                'mediumorchid',
                                'orange',
                                'lavender',
                                'steelblue',
                                'darkred',
                                'blueviolet',
                                'slateblue',
                                'olivedrab',
                                'sienna',
                                'brown',
                                'green',
                                'forestgreen',
                                'goldenrod',
                                'lightgoldenrodyellow',
                                'mediumspringgreen',
                                'cadetblue',
                                'orangered',
                                'crimson',
                                'lavenderblush',
                                'gold',
                                'darkmagenta',
                                'honeydew',
                                'wheat',
                                'deepskyblue',
                                'dimgray',
                                'khaki',
                                'aqua',
                                'aquamarine',
                                'lightsteelblue',
                                'darkolivegreen',
                                'dodgerblue',
                                'darkorange',
                                'bisque',
                                'mediumseagreen',
                                'skyblue',
                                'darkseagreen',
                                'lime',
                                'rosybrown',
                                'greenyellow',
                                'burlywood',
                                'pink',
                                'maroon',
                                'navy',
                                'lightyellow',
                                'thistle',
                                'limegreen',
                                'mediumpurple',
                                'mistyrose',
                                'salmon',
                                'yellowgreen',
			];

our $trackNoGreyJobTreeColors =
			[
                                'darkcyan',
                                'mediumturquoise',
                                'chocolate',
                                'indigo',
                                'purple',
                                'mediumslateblue',
                                'firebrick',
                                'plum',
                                'darkgoldenrod',
                                'deeppink',
                                'royalblue',
                                'lightseagreen',
                                'darkslateblue',
                                'orchid',
                                'darkkhaki',
                                'darkgreen',
                                'darkblue',
                                'hotpink',
                                'darksalmon',
                                'blue',
                                'mediumvioletred',
                                'fuchsia',
                                'lightskyblue',
                                'chartreuse',
                                'darkviolet',
                                'lightcoral',
                                'teal',
                                'seagreen',
                                'cornflowerblue',
                                'palevioletred',
                                'lightsalmon',
                                'coral',
                                'olive',
                                'darkturquoise',
                                'mediumaquamarine',
                                'cyan',
                                'saddlebrown',
                                'red',
                                'indianred',
                                'peru',
                                'turquoise',
                                'mediumblue',
                                'violet',
                                'lawngreen',
                                'darkorchid',
                                'beige',
                                'tomato',
                                'springgreen',
                                'oldlace',
                                'magenta',
                                'mediumorchid',
                                'orange',
                                'lavender',
                                'steelblue',
                                'darkred',
                                'blueviolet',
                                'slateblue',
                                'olivedrab',
                                'sienna',
                                'brown',
                                'green',
                                'forestgreen',
                                'goldenrod',
                                'lightgoldenrodyellow',
                                'mediumspringgreen',
                                'cadetblue',
                                'orangered',
                                'crimson',
                                'lavenderblush',
                                'gold',
                                'darkmagenta',
                                'honeydew',
                                'wheat',
                                'deepskyblue',
                                'dimgray',
                                'khaki',
                                'aqua',
                                'aquamarine',
                                'lightsteelblue',
                                'darkolivegreen',
                                'dodgerblue',
                                'darkorange',
                                'bisque',
                                'mediumseagreen',
                                'skyblue',
                                'darkseagreen',
                                'lime',
                                'rosybrown',
                                'greenyellow',
                                'burlywood',
                                'pink',
                                'maroon',
                                'navy',
                                'lightyellow',
                                'thistle',
                                'limegreen',
                                'mediumpurple',
                                'mistyrose',
                                'salmon',
                                'yellowgreen',
			];

our @EXPORT = qw($defaults $trackColors $trackNoGreyColors $trackNoGreyJobTreeColors $jobStatus $jobStatusName $msaTrimTypes $treeTools $treeToolsId);

1;
