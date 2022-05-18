#!/usr/bin/perl

# query fonts in registry
$reg = '/cygdrive/c/Windows/system32/reg.exe query';
$cv = 'HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion';
@known_fonts = `$reg \'$cv\\Fonts';$reg \'$cv\\Type 1 Installer\\Type 1 Fonts'`;

# remove leading and trailing lines
shift @known_fonts;
shift @known_fonts;
pop @known_fonts;

# remove a bunch of traing cruft from each line, then all whitesoace to canonicalize
@known_fonts = map {
    s/^\s+//g;
    s/ 85 /-/;
    s/\((OpenType|TrueType|All res)\).*//;
    s/[(]?[0-9,]+[)]?\s+REG_SZ.*//;
    s/[0-9,]+\s+REG_SZ.*//;
    s/\s+REG_MULTI_SZ.*//;
    s/[\s-]+//g;
    chomp;
    $_
  } @known_fonts;

# explode "packages" (fonts with "&" in name) into individual fonts
foreach $font (sort @known_fonts) {
    if ($font =~ m/\&/) {
        push @known_fonts, split /\&/, $font;
    };
}

# remove "packages" (fonts with "&" in name)
@known_fonts = grep {$_ !~ /[&]/} @known_fonts;
@files = `/usr/bin/find bin -name "*.swf"`;

print "\n\n";
print "*********************************\n";
print "* All Fonts Currently Installed *\n";
print "*********************************\n";
foreach $font (sort @known_fonts) {
    print "$font\n";
}

$rc = 0;

print "\n";
print "********************************************\n";
print "* Checking all SWF's in bin for font usage *\n";
print "********************************************\n";

if (! ($swfToolsPath = $ENV{"SWFTOOLS"})) {
    # HKLM\SOFTWARE\Wow6432Node\quiss.org\SWFTools\InstallPath
    $swfToolsPath = `$reg \'HKLM\\SOFTWARE\\Wow6432Node\\quiss.org\\SWFTools\\InstallPath\'`;
    $swfToolsPath =~ s/HKEY_.*InstallPath//;
    $swfToolsPath =~ s/\s+\(Default\)\s+REG_SZ\s+//m;
    $swfToolsPath =~ s~([a-zA-Z]):~/cygdrive/\L$1/~;
    $swfToolsPath =~ s~\s+$~~m;
}

my %missing_fonts;
foreach $file (@files) {
    chomp($file);
    my @out = `$swfToolsPath/swfdump.exe -D "$file"`;

    foreach $line (@out) {
        next unless ($line =~ m/FONTNAME/);
        chomp($line);
        @line_tmp = split("\"", $line);
        $fontname = $line_tmp[1];
        $shortname = $fontname;
        $shortname =~ s/^Arial Unicode MS/Arial/g;
        $shortname =~ s/^Avenir LT Std 85 Heavy/Avenir LT Std Heavy/g;
        $shortname =~ s/^Block Berthold /Block BE /g;
        $shortname =~ s/^Brush Script Std Medium/Brush Script Std/g;
        $shortname =~ s/^Courier Bold/Courier New Bold/g;
        $shortname =~ s/^Futura Condensed Medium/Futura Condensed /g;
        $shortname =~ s/^Futura XBlk BT Extra Black/Futura Extra Black BT/g;
        $shortname =~ s/^LCDMono Ultra/LCD Mono Light/g;
        $shortname =~ s/^Poplar Std Black/Poplar Std/g;
        $shortname =~ s/^Stencil Std Bold/Stencil Std/g;
        $shortname =~ s/^Tekton Pro Bold Condensed/Tekton Pro Bold Cond/;
        $shortname =~ s/[\s-]+//g;
        if (!grep(/$shortname/, @known_fonts)) {
            print "Added ($fontname) - $file\n";
            $missing_fonts{$fontname}++;
            $rc = 1;
        }
        if (!grep(/$shortname/, @fontlist)) {
            push @fontlist, $shortname;
        }
    }

}

print "\n\n";
print "****************************\n";
print "* All Fonts Currently Used *\n";
print "****************************\n";
foreach $font (sort @fontlist) {
    print "$font\n";
}

print "\n\n";
print "**************************\n";
print "* Unmatched Fonts In Use *\n";
print "**************************\n";
foreach $font (sort keys %missing_fonts) {
    print "$font\n";
}

exit $rc;
