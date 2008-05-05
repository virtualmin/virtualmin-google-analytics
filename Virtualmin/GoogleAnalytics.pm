package Virtualmin::GoogleAnalytics;

use strict;

use Apache2::Filter ();
use Apache2::RequestRec ();
use APR::Table ();
use Apache2::Const -compile => qw(OK DECLINED	);
use Apache2::ServerUtil ();
use Apache2::RequestUtil ();

$Virtualmin::GoolgeAnalytics::VERSION = '1.0';

# set debug level
#  0 - messages at info or debug log levels
#  1 - verbose output at info or debug log levels
$Virtualmin::GoolgeAnalytics::DEBUG = 1;

use constant BUFF_LEN => 1024;

sub handler {
    my $f = shift;
    my $account = $f->r->dir_config("AnalyticsID");
    my $mybloglog = $f->r->dir_config("MyBlogLogID");
    my $quantcast = $f->r->dir_config("QuantcastID");
    my $clicky = $f->r->dir_config("ClickyID");
    my $piwik = $f->r->dir_config("PiwikID");
    my $piwik_url = $f->r->dir_config("PiwikURL");
    if (!$account && !$mybloglog && !$quantcast && !$clicky && !$piwik) {
      # No account set yet, so nothing to do!
      return Apache2::Const::DECLINED;
    }

    # Do nothing if this isn't HTML
    my $ct = $f->r->headers_out->get('Content-Type');
    if ($ct && $ct !~ /^text\/html/i) {
      return Apache2::Const::DECLINED;
    }

    # Do nothing if this is Javascript
    my $fn = $f->r->filename();
    if ($fn && $fn =~ /\.js/i) {
      return Apache2::Const::DECLINED;
    }

    # Work out the script we want to add
    my $addscript;
    if ($account) {
      $addscript .= "<script type=\"text/javascript\">var gaJsHost = ((\"https:\" == document.location.protocol) ? \"https://ssl.\" : \"http://www.\"); document.write(unescape(\"%3Cscript src='\" + gaJsHost + \"google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E\")); </script> <script type=\"text/javascript\"> var pageTracker = _gat._getTracker(\"$account\"); pageTracker._initData(); pageTracker._trackPageview();</script>";
    }
    if ($mybloglog) {
      $addscript .= "<script type=\"text/javascript\" src=\"http://track3.mybloglog.com/js/jsserv.php?mblID=$mybloglog\"></script>";
    }
    if ($quantcast) {
      $addscript .= "<script type=\"text/javascript\" src=\"http://edge.quantserve.com/quant.js\"></script><script type=\"text/javascript\">_qacct=\"$quantcast\";quantserve();</script><noscript><img src=\"http://pixel.quantserve.com/pixel/$quantcast.gif\" style=\"display: none\" height=\"1\" width=\"1\" alt=\"Quantcast\"/></noscript>";
    }
    if ($clicky) {
      $addscript .= "<script src=\"http://static.getclicky.com/$clicky.js\" type=\"text/javascript\"></script><noscript><p><img alt=\"Clicky\" src=\"http://static.getclicky.com/${clicky}ns.gif\"/></p></noscript>";
    }
    if ($piwik) {
      $addscript .= "<!-- Piwik --><a href=\"http://piwik.org\" title=\"Web analytics\" onclick=\"window.open(this.href);return(false);\"><script language=\"javascript\" src=\"$piwik_url/piwik.js\" type=\"text/javascript\"></script><script type=\"text/javascript\"><!-- piwik_action_name = ''; piwik_idsite = $piwik; piwik_url = '$piwik_url/piwik.php'; piwik_log(piwik_action_name, piwik_idsite, piwik_url); //--> </script><object> <noscript><p>Web analytics <img src=\"$piwik_url/piwik.php\" style=\"border:0\" alt=\"piwik\"/></p> </noscript></object></a>";
<!-- /Piwik -->
    }
  
    # Clear the content length, as we modify it
    unless ($f->ctx) {
	$f->r->headers_out->unset('Content-Length');
        $f->ctx(1);
    }

    while ($f->read(my $buffer, BUFF_LEN)) {
	if ($buffer =~ /^([\000-\377]*)(<\/body[^>]*>)([\000-\377]*)$/i) {
	    $buffer = $1.$addscript.$2.$3;
	}
        $f->print($buffer);
    }
    #$f->r->headers_out->do(sub { $f->print("$_[0]: $_[1]\n") });

    return Apache2::Const::OK;
}
1;


