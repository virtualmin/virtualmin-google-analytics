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
if (!$in{'piwik_def'} && $in{'piwikurl_def'}) {
	&error($text{'save_epiwikurl2'});
	}

# Save Piwik base URL
if (!$in{'piwikurl_def'}) {
	$in{'piwikurl'} =~ /^(http|https):\/\/(\S+)$/ ||
		&error($text{'save_epiwikurl'});
	&save_perlsetvar($d, $in{'piwikurl'}, "PiwikURL");
	}

# Save head and body javascript
$headjs_file = &get_perlsetvar($d, "HeadJavascriptFile");
if ($in{'headjs'} =~ /\S/) {
	$headjs_file = "$module_config_directory/$d->{'id'}.head.js";
	&open_tempfile(HEAD, ">$headjs_file");
	&print_tempfile(HEAD, $in{'headjs'});
	&close_tempfile(HEAD);
	&set_ownership_permissions(undef, undef, 0755, $headjs_file);
	&save_perlsetvar($d, $headjs_file, "HeadJavascriptFile");
	}
else {
	&save_perlsetvar($d, undef, "HeadJavascriptFile");
	}
$bodyjs_file = &get_perlsetvar($d, "BodyJavascriptFile");
if ($in{'bodyjs'} =~ /\S/) {
	$bodyjs_file = "$module_config_directory/$d->{'id'}.body.js";
	&open_tempfile(HEAD, ">$bodyjs_file");
	&print_tempfile(HEAD, $in{'bodyjs'});
	&close_tempfile(HEAD);
	&set_ownership_permissions(undef, undef, 0755, $bodyjs_file);
	&save_perlsetvar($d, $bodyjs_file, "BodyJavascriptFile");
	}
else {
	&save_perlsetvar($d, undef, "BodyJavascriptFile");
	}

&virtual_server::run_post_actions();
&webmin_log("save", undef, $d->{'dom'});

if ($in{'virtualmin'}) {
	# Go to Virtualmin post-save page
	&redirect("../virtual-server/postsave.cgi?dom=$d->{'id'}");
	#&virtual_server::domain_redirect($d);
	}
else {
	# To domain menu
	&redirect("");
	}
