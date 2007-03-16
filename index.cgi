#!/usr/local/bin/perl
# Show domains that have analytics enabled

require './virtualmin-google-analytics-lib.pl';
&ui_print_header(undef, $text{'index_title'}, "", undef, 1, 1);

@doms = grep { &virtual_server::can_edit_domain($_) }
	     &virtual_server::list_domains();
if (!@doms) {
	# User has no domains
	print "<b>$text{'index_nodoms'}</b>\n";
	}
elsif (&indexof($module_name, @virtual_server::confplugins) < 0) {
	# Plugin is not enabled
	print "<b>",&text('index_eplugin',
		"../virtual-server/edit_newplugins.cgi"),"</b><p>\n";
	}
else {
	print $text{'index_desc'},"<p>\n";
	print &ui_columns_start([ $text{'index_dom'},
				  $text{'index_status'},
				  $text{'index_actions'} ]);
	foreach $d (@doms) {
		$has = &has_analytics_directives($d);
		$account = $has ? &get_analytics_account($d) : undef;
		@actions = ( );
		push(@actions, "<a href='edit.cgi?dom=$d->{'id'}'>".
			       "$text{'index_edit'}</a>") if ($has);
		my $prog = &virtual_server::can_config_domain($d) ?
				"edit_domain.cgi" : "view_domain.cgi";
		print &ui_columns_row([
			"<a href='../virtual-server/$prog?dom=$d->{'id'}'>$d->{'dom'}</a>",
			$account ? &text('index_account', "<tt>$account</tt>") :
			$has ? $text{'index_has'} : $text{'index_dis'},
			&ui_links_row(\@actions)
			]);
		}
	print &ui_columns_end();
	}

&ui_print_footer("/", $text{'index'});

