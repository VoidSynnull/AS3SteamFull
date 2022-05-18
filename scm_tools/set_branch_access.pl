#!/usr/bin/perl -w

# Script to automate the editing of the authz file to allow/deny access to a branch
# during release preparation.
#
# This script should be SETUID TO WEBADMIN or ROOT depending on whether svn-poptropica-authz.conf or svnauthz.conf
# is being modified.

# @version SVN: $Id: set_branch_access.pl 84632 2014-06-16 14:40:25Z ufrand3 $

use strict;

use Getopt::Long;
use Config::IniFiles;
use File::Copy;

my @defaultFiles = (
    '/etc/svnauthz.conf',   ## requires root access
);
my $base = 'poptropica:/projects/poptropica2/';

my $usage = "Usage: $0 [--file=filename] branchname lock|unlock\n";

my @files;
if (!GetOptions(
                'file=s' => \@files
                )) {
    print STDERR $usage;
    exit 1;
}
if (@files == 0) {
    @files = @defaultFiles;
}

if (@ARGV != 2) {
    print STDERR $usage;
    exit 1;
}

my $branchname = $ARGV[0];
my $state = $ARGV[1];
if ($state ne 'lock' and $state ne 'unlock') {
    print STDERR $usage;
    exit 1;
}

if ($branchname !~ m@^trunk\b|tags\b|branches\b@) {
    $branchname = 'branches/' . $branchname;
}
$branchname = $base . $branchname;

# Edit ini file(s)
for my $file (@files) {
    my $cfg = Config::IniFiles->new(-file => $file);
    if ($state eq 'lock') {
        $cfg->AddSection($branchname);
        $cfg->newval($branchname, '*', 'r');
        $cfg->newval($branchname, '@admin', 'rw');
    } elsif ($state eq 'unlock') {
        $cfg->AddSection($branchname);
        $cfg->newval($branchname, '*', 'rw');
    } else {
        print STDERR "State is $state instead of 'lock' or 'unlock'\n";
        exit 1;
    }
    my $bak = "$file.bak";
    if (-f "$bak") {
        move($bak, "$bak.bak");
    }
    if (!copy($file, "$bak")) {
        print STDERR "Could not make backup copy of $file ($!) - no changes made\n";
        next;
    }

    if ($cfg->RewriteConfig()) {
        print "$branchname now ${state}ed\n";
        print "(Old version saved in $bak)\n";
    } else {
        print STDERR "Could not rewrite $file - no changes made\n";
    }
}
