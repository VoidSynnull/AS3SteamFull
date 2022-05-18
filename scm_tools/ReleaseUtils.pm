#####
# Global functions used by other Standard Process Model utilities
#####

$SVN_REPO  = "https://vc.fen.com/svn/poptropica/projects";
$NEW_REPO  = $SVN_REPO;
$REPO_PATH = "/srv/svn/poptropica";

sub get_date {

    package ctime;
    local ($DATE_REF) = @_;
    $time = (time - $DATE_REF);
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
      localtime($time);
    $year += 1900;
    $mon_ref = (January, February, March, April, May, June,
        July, August, September, October, November, December
    )[$mon];
    $day_ref =
      (Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday)[$wday];
    if ($sec < 10) {
        $sec = "0" . $sec;
    }
    if ($min < 10) {
        $min = "0" . $min;
    }

    return ($sec, $min, $hour, $day_ref, $mday, $mon_ref, $year);
}

sub report_hdr {
    local ($NAME, @DATE_INFO) = @_;
    print "\n", "*" x 80;
    print "*$NAME\n*\t\t\t   $DATE_INFO[3], $DATE_INFO[5] $DATE_INFO[4], $DATE_INFO[6]";
    print "\n", "*" x 80, "\n";
}

sub mail_hdr {
    local ($NAME, @DATE_INFO) = @_;
    print "\n", "*" x 80, "\n";
    print "*$NAME\n*\t\t\t\t$DATE_INFO[3], $DATE_INFO[5] $DATE_INFO[4], $DATE_INFO[6]";
    print "\n", "*" x 80, "\n";
}

sub SendMail {
    local ($subject) = $_[0];
    local ($body)    = $_[1];
    local ($tolist)  = $_[2];
    $subject = "Test";
    $body    = "BODY";
    use Net::SMTP;

    $smtp = Net::SMTP->new('smtp.buyerzone.com');
    $smtp->mail('SCM_Administrator');
    $to_string = "To: ";

    @mail_list = split(" ", $tolist);
    foreach $recipient (@mail_list) {
        $smtp->to($recipient);
        $to_string = $to_string . $recipient . "; ";
    }

    $smtp->data();
    $smtp->datasend("Subject: $subject\n");
    $smtp->datasend("$to_string\n");
    $smtp->datasend("\n");
    $smtp->datasend($body);
    $smtp->dataend();
    $smtp->quit;
}

sub swap_cs {
    local ($base_label)  = $_[0];
    local ($new_label)   = $_[1];
    local ($stream_name) = $_[2];
    local ($cs_type)     = $_[3];

    $origfile = "ORIG_CS_" . "$$" . ".txt";
    if (!grep(/^0$/, @rc = system("$ct catcs >> $origfile 2>&1"))) {
        print "\nERROR: Cannot export config spec, please try again...\n\n";
        exit 1;
    }

    $newfile = "NEW_CS_" . "$$" . ".txt";
    open(NEWFILE, ">>$newfile");
    if ($cs_type eq "standard") {
        $new_cs = "element * CHECKEDOUT\nelement * .../$stream_name/LATEST\nelement * $base_label\nelement * /main/LATEST\n";
    } elsif ($cs_type eq "label") {
        $new_cs = "element * $new_label\nelement * /main/LATEST";
    } elsif ($cs_type eq "default") {
        $new_cs = "element * CHECKEDOUT\nelement * /main/LATEST\n";
    } elsif ($cs_type eq "release") {
        $new_cs = "element * $new_label\nelement * /main/LATEST\n";
    }
    print(NEWFILE $new_cs);
    close NEWFILE;

    if (!grep(/^0$/, @rc = system("$ct setcs $newfile 2>&1"))) {
        print "\nERROR: Cannot reset config spec, please try again...\n\n";
        $rc = `rm -rf $origfile`;
        $rc = `rm -rf $newfile`;
        exit 1;
    }
    return $origfile, $newfile;
}

sub unswap_cs {
    local ($origfile) = $_[0];
    local ($newfile)  = $_[1];

    if (!grep(/^0$/, @rc = system("$ct setcs $origfile 2>&1"))) {
        print "\nERROR: Cannot unswap config spec, please try again...\n\n";
        return;
    }
    $rc = `rm -rf $origfile`;
    $rc = `rm -rf $newfile`;
}

sub make_label {
    local ($project, $stream_name, $new_label) = @_;
    chomp($project, $stream_name, $new_label);

    if (!grep(/^0$/, @rc = system("svn copy $SVN_REPO/$project/branches/$stream_name $SVN_REPO/$project/tags/$new_label -m \"SCM Auto-Label\" >> /dev/null 2>&1"))) {
        print "\nERROR: Cannot create new label type, please try again...\n\n";
        return;
    }
}

return 1;
