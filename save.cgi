#!/usr/local/bin/perl
# Update the analytics account for some domain

require './virtualmin-google-analytics-lib.pl';
&ReadParse();
&error_setup($text{'save_err'});

# Validate inputs
$d = &virtual_server::get_domain($in{'dom'});
&virtual_server::can_edit_domain($d) || &error($text{'edit_ecannot'});
&has_analytics_directives($d) || &error($text{'edit_ehas'});
foreach $s (@tracking_services) {
	$in{$s->[0].'_def'} || $in{$s->[0]} =~ /^$s->[3]$/ ||
		&error($text{'save_e'.$s->[0]});
	}

# Update the server
&virtual_server::set_all_null_print();
foreach $s (@tracking_services) {
	&{$s->[2]}($d, $in{$s->[0].'_def'} ? undef : $in{$s->[0]});
	}
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
