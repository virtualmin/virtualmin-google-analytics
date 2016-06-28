#!/usr/local/bin/perl
# Show a form for setting the analytics account for some domain
use strict;
use warnings;
our (%text, %in);
our @tracking_services;

require './virtualmin-google-analytics-lib.pl';
&ReadParse();
my $d = &virtual_server::get_domain($in{'dom'});
&virtual_server::can_edit_domain($d) || &error($text{'edit_ecannot'});
&has_analytics_directives($d) || &error($text{'edit_ehas'});

&ui_print_header(&virtual_server::domain_in($d), $text{'edit_title'}, "");

print &ui_form_start("save.cgi", "post");
print &ui_hidden("virtualmin", $in{'virtualmin'}),"\n";
print &ui_hidden("dom", $in{'dom'}),"\n";
print &ui_table_start($text{'edit_header'}, undef, 2);

my $dname = defined(&virtual_server::show_domain_name) ?
	&virtual_server::show_domain_name($d) : $d->{'dom'};
print &ui_table_row($text{'edit_dom'}, "<tt>$dname</tt>");

# Show ID input for each account
foreach my $s (@tracking_services) {
	my $account = &{$s->[1]}($d);
	print &ui_table_row(&hlink($text{'edit_'.$s->[0]}, $s->[0]),
			    &ui_opt_textbox($s->[0], $account, 20,
				    $text{'edit_dis'}, $text{'edit_ena'}));
	}

# Show base URL for Piwik
my $vurl = &get_perlsetvar($d, "PiwikURL");
my $urlin;
if ($vurl) {
	$urlin = &ui_opt_textbox("piwikurl", $vurl, 40, $text{'edit_notset'});
	}
else {
	$urlin = &ui_opt_textbox("piwikurl", &get_piwik_default_url($d), 40,
				 $text{'edit_notset'});
	}
print &ui_table_row(&hlink($text{'edit_piwikurl'}, 'piwikurl'), $urlin);

# Show field for arbitrary head and body javascript
my $headjs_file = &get_perlsetvar($d, "HeadJavascriptFile");
my $headjs = $headjs_file ? &read_file_contents($headjs_file) : undef;
print &ui_table_row(&hlink($text{'edit_headjs'}, 'headjs'),
	&ui_textarea("headjs", $headjs, 5, 60));
my $bodyjs_file = &get_perlsetvar($d, "BodyJavascriptFile");
my $bodyjs = $bodyjs_file ? &read_file_contents($bodyjs_file) : undef;
print &ui_table_row(&hlink($text{'edit_bodyjs'}, 'bodyjs'),
	&ui_textarea("bodyjs", $bodyjs, 5, 60));

print &ui_table_end();
print &ui_form_end([ [ "save", $text{'save'} ] ]);

&ui_print_footer("", $text{'index_return'});

