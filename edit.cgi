#!/usr/local/bin/perl
# Show a form for setting the analytics account for some domain

require './virtualmin-google-analytics-lib.pl';
&ReadParse();
$d = &virtual_server::get_domain($in{'dom'});
&virtual_server::can_edit_domain($d) || &error($text{'edit_ecannot'});
&has_analytics_directives($d) || &error($text{'edit_ehas'});

&ui_print_header(&virtual_server::domain_in($d), $text{'edit_title'}, "");

print &ui_form_start("save.cgi", "post");
print &ui_hidden("virtualmin", $in{'virtualmin'}),"\n";
print &ui_hidden("dom", $in{'dom'}),"\n";
print &ui_table_start($text{'edit_header'}, undef, 2);

print &ui_table_row($text{'edit_dom'}, "<tt>$d->{'dom'}</tt>");

# Analytics account
$account = &get_analytics_account($d);
print &ui_table_row($text{'edit_account'},
		    &ui_opt_textbox("account", $account, 20,
				    $text{'edit_dis'}, $text{'edit_ena'}));

print &ui_table_end();
print &ui_form_end([ [ "save", $text{'save'} ] ]);

&ui_print_footer("", $text{'index_return'});
