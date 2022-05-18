#!/usr/bin/perl -w

#####
# Include variables and subroutines
#####
use FindBin qw($Bin);
use lib "$Bin";
use ReleaseUtils;
use lib "$Bin/..";
use Release;

$svn = "svn";

#####
# Verify and/or prompt for command line arguments
#####
if (scalar @ARGV != 4 && scalar @ARGV != 5) {
    $script_name = `basename $0`;
    chomp($script_name);
    &Usage($script_name);
} else {
    $env     = uc($ARGV[0]);
    $base    = $ARGV[1];
    $base    =~ s=^/==;
    $base    =~ s=/$==;
    $rel     = $ARGV[2];
    $rel     =~ s=^/==;
    $rel     =~ s~/$~~;
    $project = $ARGV[3];
    $keep    = $ARGV[4];
    chomp($keep) if ($keep);
    $tag = substr($rel, 4);
    if ($env eq "DEV") {
        $mail_list = $dev_mail;
        @rel_hosts = @dev_hosts;
        $site_url = $dev_url;
    } elsif ($env eq "QA") {
        $mail_list = $qa_mail;
        @rel_hosts = @qa_hosts;
        $site_url = $qa_url;
#    } elsif ($env eq "STG") {
#        $mail_list = $stg_mail;
#        @rel_hosts = @stg_hosts;
    } elsif ($env eq "PRD") {
        $mail_list = $prd_mail;
        @rel_hosts = @prd_hosts;
        $site_url = $prd_url;
    } else {
        print "\nUnknown release environment '$env'\n";
        exit;
    }
}

#####
# Set user variables
#####
$user = $ENV{'LOGNAME'};
chomp($user);

$release_team = "";
if ($release_team) {
    $mail_list = $mail_list . $release_team;
}

$NOTE_DIR = '.';
if (! -w $NOTE_DIR) {
    $NOTE_DIR = "$ENV{'HOME'}/.poprelease";
    print "Using $NOTE_DIR to hold release note\n";
}

$LOG      = "$NOTE_DIR/ReleaseNote_$tag.txt.$$";
$KEEP_LOG = "$NOTE_DIR/ReleaseNote_$tag.txt";

print "$LOG\n";
@date_info = &get_date(0);
local $rel_time = "$date_info[3], $date_info[5] $date_info[4], $date_info[6]";
$subject = "SCM: Project Release Notice ($project - $rel) - $rel_time";

open(LOG, ">>$LOG") || die "Cannot open logfile $!";
&Header($env, $base, $rel, $project);
&Mod_Data($base, $rel, $project);
close LOG;

if ($keep && $keep eq "keep") {
    $mail_list = $release_team;
    open(OLD_LOG, "$LOG");
    open(NEW_LOG, ">>$KEEP_LOG");
    @lines = <OLD_LOG>;
    print NEW_LOG @lines;
    close NEW_LOG;
    close OLD_LOG;
} else {
    $project = uc($project);
}

$mail_list =~ s/\\//;
if ($keep && $keep eq "mail") {
    $rc = `cat $LOG | /bin/mailx -s "$subject" $mail_list`;
    #Mail delivery has become unreliable - leave file around until we know it was received
    #$rc = system("rm $LOG");
    print "Release notes are in $LOG\n";
}

exit;

sub Usage {
    local ($script_name) = $_[0];
    print <<"EOF";

Usage: $script_name <Environment> <Reference> <Release> <Project>

 <Environment>	Release Environment for this release (DEV,QA1,QA2,STG,PRD)
 <Reference>	Previous release baseline (PROJECT_1.0)
 <Release>	This release version (PROJECT_1.2.0.3)
 <Project>	The project name (Project)

EOF

    exit;
}

sub Header {
    local ($env, $base, $rel, $project) = @_;

    $ucproject = uc($project);
    print LOG "\n", "*" x 80;
    print LOG "\n* Project Release Notice - $rel_time";
    print LOG "\n", "*" x 80, "\n";
    print LOG "\nProject Name : $ucproject";
    print LOG "\nRelease Version : $rel";
    print LOG "\nRelease Engineer : $user\n";
    print LOG "\nRuntime Environment : $env";
    print LOG "\nSite URL : $site_url\n";
}

sub Mod_Data {
    local ($base, $rel, $project) = @_;

    if (
        !grep(/^0$/,
            @rc = system("$svn list $SVN_REPO/$project >> /dev/null 2>&1"))
      )
    {
        print
          "\nProject name ($project) not found, please verify and try again\n";
        exit 1;
    }

    if (
        !grep(/^0$/,
            @rc = system(
                "$svn list $SVN_REPO/$project/tags/$base >> /dev/null 2>&1"))
      )
    {
        print "\nBase label ($base) not found, please verify and try again\n";
        exit 1;
    }
    if (
        !grep(/^0$/,
            @rc = system(
                "$svn list $SVN_REPO/$project/tags/$rel >> /dev/null 2>&1"))
      )
    {
        print "\nRelease label ($rel) not found, please verify and try again\n";
        exit 1;
    }

    print "  Run svn diff $SVN_REPO/$project/tags/$base $SVN_REPO/$project/tags/$rel ...\n";
    @full_list = `$svn diff --summarize $SVN_REPO/$project/tags/$base $SVN_REPO/$project/tags/$rel`;

    foreach $line (@full_list) {
        @fields = split(" ", $line);
        if ($fields[0] eq "M" || $fields[0] eq "MM") {
            push @mod_list, $fields[1];
        } elsif ($fields[0] eq "A") {
            push @new_list, $fields[1];
        } elsif ($fields[0] eq "D") {
            push @rm_files, $fields[1];
        } else {
            print "\nUnknown error on ($line), please verify and try again\n";
            exit 1;
        }
    }

    #    @crm_list=&crm_rpt($project,$rel);

    #    if ( @crm_list ) {
    # print LOG "\n", "*" x 80;
    # print LOG "\n* CRM Items found in this release, $rel";
    # print LOG "\n", "*" x 80, "\n\n";

    # print LOG "No Source Code Control/Change Request Management System integration in place, TBD\n";

    #    }

    #    if ( @no_lbl ) {
    #        print LOG "\n", "*" x 80;
    #        print LOG "\n* Following files have no label, $base or $rel";
    #        print LOG "\n", "*" x 80, "\n";
    #        print LOG join("\n",@no_lbl);
    #        print LOG "\n";
    #    }

    if (@new_list) {
        @new_det = @new_list;
        print LOG "\n", "*" x 80;
        print LOG "\n* NEW files from $base to $rel";
        print LOG "\n", "*" x 80, "\n\n";
        foreach $file (sort @new_list) {
            chomp($file);
            $file =~ s~$SVN_REPO/$project/tags/$base/~~;
            print LOG "$file\n";
        }
        print LOG "\n", "*" x 80;
        print LOG "\n* NEW file details";
        print LOG "\n", "*" x 80, "\n\n";
        foreach $file_det (sort @new_det) {
            $file_det =~ s~/$base/~/$rel/~;
            $ci_info = `svn log '$file_det'@`;
            $ci_info =~ s/^-+\n//msg;
            $ci_info =~ s/^r\d+ \| //mg;
            $ci_info =~ s/ \| [^|]+//g;
            $ci_info =~ s/\| \d+ line\n\n/: /msg;
            $ci_info =~ s/^.*$//m;
            $ci_info =~ s/^pjenkadm: .*?$//mg;
            $ci_info =~ s/\n\n/\n/mg;
            chomp($ci_info);
            $ci_info =~ s/^/\t/mg;
            $file_det =~ s~$SVN_REPO/$project/tags/$rel/~~;

            print LOG "- $file_det$ci_info\n\n";
        }
    }

    if (@mod_list) {
        @mod_det = @mod_list;
        print LOG "*" x 80;
        print LOG "\n* MODIFIED files from release $base to $rel";
        print LOG "\n", "*" x 80, "\n\n";
        foreach $file (sort @mod_list) {
            chomp($file);
            $file =~ s~$SVN_REPO/$project/tags/$base/~~;
            print LOG "$file\n";
        }
        print LOG "\n", "*" x 80;
        print LOG "\n* MODIFIED file details";
        print LOG "\n", "*" x 80, "\n\n";
        my $rev;
        foreach $file_det (sort @mod_det) {
            $file_det =~ s~/$base/~/$rel/~;
            $rev = `$svn info '$file_det'@`;
            $rev =~ s/.*\nLast Changed Rev: (\d+).*/$1/ms;
            @ci_info = `svn log -r $rev $SVN_REPO`;
            # Example output of svn log:
            # ------------------------------------------------------------------------
            # r112423 | uhockri | 2015-12-22 11:36:01 -0500 (Tue, 22 Dec 2015) | 1 line
            # 
            # photo booth location has changed
            # ------------------------------------------------------------------------
            print "No output from svn log -r $rev $SVN_REPO\n" if (scalar(@ci_info) == 0);
            shift(@ci_info) if ($ci_info[0] =~ /^---------/);
            my($ci_rev, $ci_user, $ci_timestamp, $ci_n_lines) = split(/ \| /, shift(@ci_info));
            chomp($ci_user);
            while (scalar(@ci_info) > 0 && $ci_info[0] =~ /^\s*/) {
                shift(@ci_info);
            }
            pop(@ci_info) if (scalar(@ci_info) > 0 && $ci_info[$#ci_info] =~ /^--------------/);
            $ci_cmnt = join("\n", @ci_info);
            chomp($ci_cmnt);

            $file_det =~ s~$SVN_REPO/$project/tags/$rel/~~;

            print LOG "- $file_det\n\t$ci_user: $ci_cmnt\n\n";
        }
    }

    if (@rm_files) {
        print LOG "*" x 80;
        print LOG "\n* Following files have been removed from $base to $rel";
        print LOG "\n", "*" x 80, "\n\n";
        foreach $rm_file (@rm_files) {
            $rm_file =~ s~$SVN_REPO/$project/tags/~~;
            print LOG "$rm_file\n";
        }
    }


    if (!@rm_files && !@new_list && !@mod_list) {
        print LOG "\n\n", "*" x 52;
        print LOG "\n*** No source code changes, Content Release Only ***";
        print LOG "\n", "*" x 52;
    } else {
        print LOG "\n", "*" x 80;
        print LOG "\n*** Release Metrics Summary - $base to $rel";
        print LOG "\n", "*" x 80;
        $rm_cnt = (@rm_files);
        print LOG "\n***\t\t\t\tTotal # of removed files  = $rm_cnt";
        $new_cnt = (@new_list);
        print LOG "\n***\t\t\t\tTotal # of new files         = $new_cnt";
        $mod_cnt = (@mod_list);
        print LOG "\n***\t\t\t\tTotal # of modified files   = $mod_cnt";
        print LOG "\n", "*" x 80, "\n", "*" x 80, "\n";
    }
}

sub crm_rpt {
    local ($project, $rel) = @_;

    @full_list = `svn log -v $SVN_REPO/$project/tags/$rel | grep "^JIRA Number: "`;
    foreach $line (@full_list) {
        @flds = split(":", $line);
        $tmp_crm = $flds[1];
        chomp($tmp_crm);
        if (!grep(/$tmp_crm/, @crm_list)) {
            $tmp_crm =~ s/ //g;
            push @crm_list, $tmp_crm;
        }
    }
    return @crm_list;
}
