#!/usr/local/bin/perl
# Update the analytics account for some domain
use strict;
use warnings;
our (%text, %in);
our @tracking_services;
our $module_config_directory;

require './virtualmin-google-analytics-lib.pl';
&ReadParse();
&error_setup($text{'save_err'});

# Validate inputs
my $d = &virtual_server::get_domain($in{'dom'});
&virtual_server::can_edit_domain($d) || &error($text{'edit_ecannot'});
&has_analytics_directives($d) || &error($text{'edit_ehas'});
foreach my $s (@tracking_services) {
	$in{$s->[0].'_def'} || $in{$s->[0]} =~ /^$s->[3]$/ ||
		&error($text{'save_e'.$s->[0]});
	}

# Update the server
&virtual_server::set_all_null_print();
foreach my $s (@tracking_services) {
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
my $headjs_file = &get_perlsetvar($d, "HeadJavascriptFile");
if ($in{'headjs'} =~ /\S/) {
	$headjs_file = "$module_config_directory/$d->{'id'}.head.js";
	no strict "subs";
	&open_tempfile(HEAD, ">$headjs_file");
	&print_tempfile(HEAD, $in{'headjs'});
	&close_tempfile(HEAD);
	use strict "subs";
	&set_ownership_permissions(undef, undef, 0755, $headjs_file);
	&save_perlsetvar($d, $headjs_file, "HeadJavascriptFile");
	}
else {
	&save_perlsetvar($d, undef, "HeadJavascriptFile");
	}
my $bodyjs_file = &get_perlsetvar($d, "BodyJavascriptFile");
if ($in{'bodyjs'} =~ /\S/) {
	$bodyjs_file = "$module_config_directory/$d->{'id'}.body.js";
	no strict "subs";
	&open_tempfile(HEAD, ">$bodyjs_file");
	&print_tempfile(HEAD, $in{'bodyjs'});
	&close_tempfile(HEAD);
	use strict "subs";
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
