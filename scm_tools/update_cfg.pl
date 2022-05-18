#!/usr/bin/perl

# Setting any defaults for testing
$rel_ver  = "999.999.999";
$bld_type = "bad";
$rel_env  = "NONE";

# Set global variables
$|       = 1;
$rel_env = $ARGV[0];
chomp($rel_env);
$bld_type = lc($ARGV[1]);
chomp($bld_type);
$rel_ver = $ARGV[2];
chomp($rel_ver);
$build_time = `date +"%r on %D"`;
chomp($build_time);

@cfg_files = (
    "src/AndroidShell-app.xml", "src/IosShell-app.xml",
);

foreach $file (@cfg_files) {
    print "* Updating source file - $file\n";
    if (grep(/AndroidShell-app.xml$/, $file)) {
        &update_android($file, $rel_env, $rel_ver);
    } elsif (grep(/IosShell-app.xml$/, $file)) {
        &update_ios($file, $rel_env, $rel_ver);
    }
}

print "\n";

exit 0;

sub update_android {
    local ($file, $rel_env, $rel_ver) = @_;

    $OLD_FILE = "$file";
    $NEW_FILE = "$file";
    $NEW_FILE =~ s~src/~src/$ARGV[1]-~;
    open(OLD_FILE, "$OLD_FILE");
    @lines = <OLD_FILE>;
    close OLD_FILE;
    open(NEW_FILE, ">$NEW_FILE");
    if ($rel_env eq "DEV") {
        $mobile_id   = "com.pearson.poptropicadev";
        $mobile_name = "DEV-Poptropica-Android";
    } elsif ($rel_env eq "QA") {
        $mobile_id   = "com.pearson.poptropica.android";
        $mobile_name = "QA-Poptropica-Android";
    } elsif ($rel_env eq "PRD") {
        $mobile_id   = "com.pearsoned.poptropica";
        $mobile_name = "PRD-Poptropica-Android";
    }
    foreach $line (@lines) {
        if (grep(/0.0.0/, $line)) {
            $line =~ s/0.0.0/$rel_ver/;
        }
        if (grep(/com.pearson.poptropicadev/, $line)) {
            if ($bld_type eq "debug") {
                $line =~ s/com.pearson.poptropicadev/$mobile_id.$bld_type/;
            } else {
                $line =~ s/com.pearson.poptropicadev/$mobile_id/;
            }
        }
        if (grep(/DEV-Poptropica-Android/, $line)) {
            if ($bld_type eq "debug") {
                $line =~ s/DEV-Poptropica-Android/$mobile_name-$bld_type/;
            } else {
                $line =~ s/DEV-Poptropica-Android/$mobile_name/;
            }
        }
        print NEW_FILE $line;
    }
    close(NEW_FILE);
}

sub update_ios {
    local ($file, $rel_env, $rel_ver) = @_;

    $OLD_FILE = "$file";
    $NEW_FILE = "$file";
    $NEW_FILE =~ s~src/~src/$ARGV[1]-~;
    open(OLD_FILE, "$OLD_FILE");
    @lines = <OLD_FILE>;
    close OLD_FILE;
    open(NEW_FILE, ">$NEW_FILE");
    if ($rel_env eq "DEV") {
        $mobile_id   = "com.pearsoned.poptropicadev";
        $mobile_name = "DEV-Poptropica-iOS";
    } elsif ($rel_env eq "QA") {
        $mobile_id   = "com.pearsoned.poptropica.ios";
        $mobile_name = "QA-Poptropica-iOS";
    } elsif ($rel_env eq "PRD") {
        $mobile_id = "com.pearsoned.poptropica";
    }
    foreach $line (@lines) {
        if (grep(/0.0.0/, $line)) {
            $line =~ s/0.0.0/$rel_ver/;
        }
        if (grep(/com.pearsoned.poptropicadev/, $line)) {
            if ($bld_type eq "debug") {
                $line =~ s/com.pearsoned.poptropicadev/$mobile_id.$bld_type/;
            } else {
                $line =~ s/com.pearsoned.poptropicadev/$mobile_id/;
            }
        }
        if (grep(/DEV-Poptropica-iOS/, $line)) {
            if ($rel_env eq "PRD") {
                $line =~ s/DEV-Poptropica-iOS/Poptropica/;
            } elsif ($bld_type eq "debug") {
                $line =~ s/DEV-Poptropica-iOS/$mobile_name-$bld_type/;
            } else {
                $line =~ s/DEV-Poptropica-iOS/$mobile_name/;
            }
        }
        print NEW_FILE $line;
    }
    close(NEW_FILE);
}
