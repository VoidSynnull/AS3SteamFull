#!/usr/bin/perl

@fla_files = `find assets -name "*.fla"`;
@swf_files = `find bin -name "*.swf"`;
@grp_files = ("interactive.fla","foreground.fla","background.fla","backdrop.fla","hits.fla");
@grp_files2 = ("interactive.swf","foreground.swf","background.swf","backdrop.swf","hits.swf");


print " Verifying SWF's to FLA's...\n";
foreach $swf ( @swf_files ) {
    chomp($swf);
#    $height =`/cygdrive/c/SWFTools/swfdump.exe -D $swf | grep "Movie height"`; 
#    chomp($height);
#    print ("$height - $swf\n");
#    next;
    $swf =~ s/^bin\///;
    $swf =~ s/.swf$/.fla/;
    if ( ! -f $swf ) {
	$layers_found = "";
	$tmp_swf = "";
	foreach $combo ( @grp_files ) {
	    if ( grep(/$combo/,$swf) ) {
		$tmp_swf = $swf;
		$tmp_swf =~ s/$combo/layers.fla/;
		if ( -f $tmp_swf ) {
		    $layers_found = "yes";
		}	
	    }
	}
	if ( $layers_found ne "yes" && ! grep(/\/testIsland\//, $swf) && ! grep(/\/examples\//, $swf) ) {
	    print "Missing - $swf\n";
	    ++$miss_fla;
	}
    }
}
print "Total missing FLA source files = $miss_fla\n\n";

print " Verifying FLA's to SWF's...\n";
foreach $fla ( @fla_files ) {
    chomp($fla);
    $fla = "bin/" . $fla;
    $fla =~ s/.fla$/.swf/;

    if ( ! -f $fla ) {
	$layers_found = "";
	$tmp_fla = "";
	foreach $combo ( @grp_files2 ) {
	    if ( grep(/layers.swf/,$fla) ) {
		$tmp_fla = $fla;
		$tmp_fla =~ s/layers.swf/$combo/;
		if ( -f $tmp_fla ) {
		    $layers_found = "yes";
		}	
	    }
	}
	if ( $layers_found ne "yes" && ! grep(/\/testIsland\//, $fla) && ! grep(/\/examples\//, $fla) ) {
	    print "Missing - $fla\n";
	    ++$miss_swf;
	}
    }
}
print "Total missing SWF binaries files = $miss_swf\n\n";

exit;
