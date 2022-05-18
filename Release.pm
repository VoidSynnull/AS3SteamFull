package Release;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( @dev_hosts @qa_hosts @prd_hosts $dev_mail $qa_mail $prd_mail $dev_url $qa_url $prd_url);

use strict;
use warnings;

our $dev_mail = "poptropica-code\@fen.com poptropicaads\@fen.com ";
our $qa_mail  = $dev_mail;
our $prd_mail = $dev_mail;

our $branchname = '%BRANCHNAME%';

our @dev_hosts = qw( usbost-fenvli08.fen.com);
our @qa_hosts = qw( usbost-fenvli08.fen.com );
our @prd_hosts = qw(
  i.www78.poptropica.com
  i.www79.poptropica.com
  i.www80.poptropica.com
  i.www83.poptropica.com
  i.www145.poptropica.com
  i.www146.poptropica.com
  i.www147.poptropica.com
  i.www151.poptropica.com
  i.www250.poptropica.com
  i.www111.poptropica.com
  i.lin259.poptropica.com
  i.lin144.poptropica.com
  i.www153.poptropica.com
  i.www154.poptropica.com
  i.www225.poptropica.com
  i.www226.poptropica.com
  i.www24.poptropica.com
  i.www19.poptropica.com
  i.brain.poptropica.com
  i.www248.poptropica.com
);

our $dev_url = "http://svn-branches-$branchname.dev.poptropica.com";
our $qa_url = "http://qa.poptropica.com";
our $prd_url = "http://www.poptropica.com";

#@stg_hosts="stgweb301\nSite URL : http://stg.domain.com:8080";

1;
