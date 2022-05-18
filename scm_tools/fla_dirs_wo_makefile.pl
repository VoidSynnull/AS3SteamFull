#!/usr/bin/perl

@all_dirs = `find . -type d | grep -v ".svn" | grep -v "\/testIsland\/" | grep -v "examples" | grep -v "\/Legacy\/" | grep -v "_template"`;

foreach $dir ( sort @all_dirs ) {
    chomp($dir);
    @src_files = "";
    @src_files = `ls $dir/*.fla 2>/dev/null`;
    $field_cnt=(@src_files);    
    if ( $field_cnt > 0 && ! -f "$dir/Makefile" ) {
	print "No Makefile - $dir\n";
    } elsif ( $field_cnt > 0 && ! `grep "^SRCS" $dir/Makefile` ) {
	print "Needs split - $dir\n";
    }
}

exit;
