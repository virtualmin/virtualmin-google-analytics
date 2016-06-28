# log_parser.pl
# Functions for parsing this module's logs
use strict;
use warnings;

do 'virtualmin-google-analytics-lib.pl';

# parse_webmin_log(user, script, action, type, object, &params)
# Converts logged information from this module into human-readable form
sub parse_webmin_log
{
my ($user, $script, $action, $type, $object, $p) = @_;
if ($action eq 'save') {
	return &text('log_save', "<tt>".&html_escape($object)."</tt>");
	}
return undef;
}

1;

