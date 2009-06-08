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
    my $woopra = $f->r->dir_config("WoopraID");
    my $piwik = $f->r->dir_config("PiwikID");
    my $piwik_url = $f->r->dir_config("PiwikURL");
    my $ssl =  $f->r->dir_config("SSL");
    if (!$account && !$mybloglog && !$quantcast && !$clicky &&
	!$woopra && !$piwik) {
      # No account set yet, so nothing to do!
      return Apache2::Const::DECLINED;
    }

    # Do nothing if this isn't HTML
    my $ct = $f->r->headers_out->get('Content-Type');
    if ($ct && $ct !~ /^text\/html/i) {
      return Apache2::Const::DECLINED;
    }

    # Do nothing if this is Javascript or looks like an image
    my $fn = $f->r->filename();
    if ($fn && $fn =~ /\.(js|jpg|png|gif|jpeg|zip|tar|gz|bz2|jar|rev|doc|xls|ppt)$/i) {
      return Apache2::Const::DECLINED;
    }

    # Work out the script we want to add
    my $addscript;
    if ($account) {
      $addscript .= "<script type=\"text/javascript\">var gaJsHost = ((\"https:\" == document.location.protocol) ? \"https://ssl.\" : \"http://www.\"); document.write(unescape(\"%3Cscript src='\" + gaJsHost + \"google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E\")); </script> <script type=\"text/javascript\"> try { var pageTracker = _gat._getTracker(\"$account\"); pageTracker._trackPageview(); } catch(err) { }</script>";
    }
    if ($mybloglog) {
      $addscript .= "<script type=\"text/javascript\" src=\"http://track3.mybloglog.com/js/jsserv.php?mblID=$mybloglog\"></script>";
    }
    if ($quantcast) {
      my $base = $ssl ? "https://secure.quantserve.com"
		      : "http://edge.quantserve.com";
      $addscript .= "<script type=\"text/javascript\" src=\"$base/quant.js\"></script><script type=\"text/javascript\">_qacct=\"$quantcast\";quantserve();</script><noscript><img src=\"$base/pixel/$quantcast.gif\" style=\"display: none\" height=\"1\" width=\"1\" alt=\"Quantcast\"/></noscript>";
    }
    if ($clicky) {
      $addscript .= "<script src=\"http://static.getclicky.com/$clicky.js\" type=\"text/javascript\"></script><noscript><p><img alt=\"Clicky\" src=\"http://static.getclicky.com/${clicky}ns.gif\"/></p></noscript>";
    }
    if ($woopra) {
      $addscript .= "<script type=\"text/javascript\">var _wh = ((document.location.protocol=='https:') ? \"https://sec1.woopra.com\" : \"http://static.woopra.com\"); document.write(unescape(\"%3Cscript src='\" + _wh + \"/js/woopra.js' type='text/javascript'%3E%3C/script%3E\"));</script>";
    }
    if ($piwik) {
      $piwik_url .= "/" if ($piwik_url !~ /\/$/);
      my $piwik_sslurl = $piwik_url;
      $piwik_sslurl =~ s/^http:/https:/;
      $addscript .= "<script type=\"text/javascript\">var pkBaseURL = ((\"https:\" == document.location.protocol) ? \"$piwik_sslurl\" : \"$piwik_url\"); document.write(unescape(\"%3Cscript src='\" + pkBaseURL + \"piwik.js' type='text/javascript'%3E%3C/script%3E\"));</script><script type=\"text/javascript\">try { var piwikTracker = Piwik.getTracker(pkBaseURL + \"piwik.php\", $piwik); piwikTracker.trackPageView(); piwikTracker.enableLinkTracking(); } catch( err ) {}</script>";
    }
  
    my $added = 0;
    while ($f->read(my $buffer, 64000)) {
	if ($buffer =~ /^([\000-\377]*)(<\/body[^>]*>)([\000-\377]*)$/i) {
	    $buffer = $1.$addscript.$2.$3;
            $added = 1;
	    if (!$f->ctx) {
		# Clear the content length, as we modify it
		$f->r->headers_out->unset('Content-Length');
		$f->ctx(1);
	    }
	}
        $f->print($buffer);
    }

    return Apache2::Const::OK;
}
1;


