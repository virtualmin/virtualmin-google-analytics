#!/usr/local/bin/perl
# Show domains that have analytics enabled
use strict;
use warnings;
our %text;
our $module_name;
our @tracking_services;

require './virtualmin-google-analytics-lib.pl';
&ui_print_header(undef, $text{'index_title'}, "", undef, 1, 1);

my @doms = grep { &virtual_server::can_edit_domain($_) && !$_->{'alias'} }
	     &virtual_server::list_domains();
no warnings "once"; # XXX sniffy.
if (!@doms) {
	# User has no domains
	print "<b>$text{'index_nodoms'}</b>\n";
	}
elsif (&indexof($module_name, @virtual_server::confplugins) < 0) {
	# Plugin is not enabled
	print "<b>",&text('index_eplugin',
		"../virtual-server/edit_newfeatures.cgi"),"</b><p>\n";
	}
else {
	# Make table rows
	my @table;
	foreach my $d (@doms) {
		my $has = &has_analytics_directives($d);
		my @accounts;
		if ($has) {
			# Find all tracking services
			foreach my $s (@tracking_services) {
				my $a = &{$s->[1]}($d);
				if ($a) {
					push(@accounts,
					     &text('index_'.$s->[0], $a));
					}
				}
			}
		my @actions;
		push(@actions, "<a href='edit.cgi?dom=$d->{'id'}'>".
			       "$text{'index_edit'}</a>") if ($has);
		my $prog = &virtual_server::can_config_domain($d) ?
				"edit_domain.cgi" : "view_domain.cgi";
		my $dname = defined(&virtual_server::show_domain_name) ?
			&virtual_server::show_domain_name($d) : $d->{'dom'};
		push(@table, [
			"<a href='../virtual-server/$prog?dom=$d->{'id'}'>".
			  "$dname</a>",
			@accounts ? join("<br>", @accounts) :
			  $has ? $text{'index_has'} : $text{'index_dis'},
			&ui_links_row(\@actions)
			]);
		}

	# Render the table
	print $text{'index_desc'},"<p>\n";
	print &ui_columns_table(
	  [ $text{'index_dom'}, $text{'index_status'}, $text{'index_actions'} ],
	  100, \@table, undef, 1);
	}
use warnings "once";

&ui_print_footer("/", $text{'index'});

