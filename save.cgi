#!/usr/local/bin/perl
# Update the analytics account for some domain

require './virtualmin-google-analytics-lib.pl';
&ReadParse();
&error_setup($text{'save_err'});

# Validate inputs
$d = &virtual_server::get_domain($in{'dom'});
&virtual_server::can_edit_domain($d) || &error($text{'edit_ecannot'});
&has_analytics_directives($d) || &error($text{'edit_ehas'});
$in{'account_def'} || $in{'account'} =~ /^[A-Za-z0-9\-]+$/ ||
	&error($text{'save_eaccount'});
$in{'mybloglog_def'} || $in{'mybloglog'} =~ /^\d+$/ ||
	&error($text{'save_emybloglog'});

# Update the server
&virtual_server::set_all_null_print();
&save_analytics_account($d, $in{'account_def'} ? undef : $in{'account'});
&save_mybloglog_account($d, $in{'mybloglog_def'} ? undef : $in{'mybloglog'});
&virtual_server::run_post_actions();

if ($in{'virtualmin'}) {
	# Go to Virtualmin post-save page
	&redirect("../virtual-server/postsave.cgi?dom=$d->{'id'}");
	#&virtual_server::domain_redirect($d);
	}
else {
	# To domain menu
	&redirect("");
	}
