#!/usr/bin/perl

$build_time = `date +"%r on %D"`;
chomp($build_time);
$svn_revision = $ENV{'SVN_REVISION'};

$outdir = "./src/engine/util";
$infile = $outdir . "/Console.as";
$outfile = $infile . ".tmp";

if ( ! -f $infile ) {
    print "\nError: Input file $infile does not exist\n@rc\n";
    exit 1;
}

open(INFILE, "$infile");
@orig_file=<INFILE>;
close INFILE;

open(OUTFILE, ">>$outfile");

foreach $line ( @orig_file ) {
    chomp($line);
    if ( grep(/SVN_REVISION/,$line) || grep(/BUILD_TIME/,$line) ) {
	$line =~ s/\@BUILD_TIME\@/$build_time/;
	$line =~ s/\@SVN_VERSION\@/SVN Revision: $svn_revision/;
    }
    print OUTFILE $line . "\n";;
}

close OUTFILE;

exit;
