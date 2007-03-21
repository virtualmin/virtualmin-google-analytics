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
    if (!$account && !$mybloglog && !$quantcast) {
      # No account set yet, so nothing to do!
      return Apache2::Const::DECLINED;
    }

    # Do nothing if this isn't HTML
    my $ct = $f->r->headers_out->get('Content-Type');
    if ($ct && $ct !~ /^text\/html/i) {
      return Apache2::Const::DECLINED;
    }

    # Work out the script we want to add
    my $addscript;
    if ($account) {
      $addscript .= "<script src=\"http://www.google-analytics.com/urchin.js\" type=\"text/javascript\"></script> <script type=\"text/javascript\">_uacct = \"$account\"; urchinTracker();</script>";
    }
    if ($mybloglog) {
      $addscript .= "<script type=\"text/javascript\" src=\"http://track3.mybloglog.com/js/jsserv.php?mblID=$mybloglog\"></script>";
    }
    if ($quantcast) {
      $addscript .= "<script type=\"text/javascript\" src=\"http://edge.quantserve.com/quant.js\"></script><script type=\"text/javascript\">_qacct=\"$quantcast\";quantserve();</script><noscript><img src=\"http://pixel.quantserve.com/pixel/$quantcast.gif\" style=\"display: none\" height=\"1\" width=\"1\" alt=\"Quantcast\"/></noscript>";
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


