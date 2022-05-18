#!/usr/bin/perl

$outdir=@ARGV[0];
chomp($outdir);
$infile = $outdir . "/build.jsfl";
if ( ! -f $infile ) {
    exit 0;
}

open(ORIG_FILE, "$infile");
@orig_lines=<ORIG_FILE>;
close ORIG_FILE;

$file_cntr = 1;
$out_fn = $outdir . "/build" . $file_cntr . ".jsfl";
open(OUTFILE, ">>$out_fn");

print "\n##################################################################################################";
print "\n# Processing $infile";
print "\n##################################################################################################\n\n";
print "Writing to file " . $out_fn . "...\n";

foreach $line ( @orig_lines ) {
    chomp($line);
    if ( $line_cnt > 1999 ) {
	print OUTFILE "fl.quit(true);\n";
	close OUTFILE;
	$file_cntr++;
	$out_fn = $outdir . "/build" . $file_cntr . ".jsfl";
	open(OUTFILE, ">>$out_fn");
	print "Writing to file " . $out_fn . "...\n";
	$line_cnt = 0;
    }
    print OUTFILE $line . "\n";
    $line_cnt++;
}

print OUTFILE "fl.quit(true);\n";
close OUTFILE;

exit;
