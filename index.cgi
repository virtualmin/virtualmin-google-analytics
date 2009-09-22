#!/usr/local/bin/perl
# Show domains that have analytics enabled

require './virtualmin-google-analytics-lib.pl';
&ui_print_header(undef, $text{'index_title'}, "", undef, 1, 1);

@doms = grep { &virtual_server::can_edit_domain($_) && !$_->{'alias'} }
	     &virtual_server::list_domains();
if (!@doms) {
	# User has no domains
	print "<b>$text{'index_nodoms'}</b>\n";
	}
elsif (&indexof($module_name, @virtual_server::confplugins) < 0) {
	# Plugin is not enabled
	$cgi = $virtual_server::module_info{'version'} >= 3.47 ?
		"edit_newfeatures.cgi" : "edit_newplugins.cgi";
	print "<b>",&text('index_eplugin',
		"../virtual-server/$cgi"),"</b><p>\n";
	}
else {
	# Make table rows
	@table = ( );
	foreach $d (@doms) {
		$has = &has_analytics_directives($d);
		@accounts = ( );
		if ($has) {
			# Find all tracking services
			foreach $s (@tracking_services) {
				$a = &{$s->[1]}($d);
				if ($a) {
					push(@accounts,
					     &text('index_'.$s->[0], $a));
					}
				}
			}
		@actions = ( );
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

&ui_print_footer("/", $text{'index'});

