use strict;
use warnings;
our $module_name;

do 'virtualmin-google-analytics-lib.pl';

sub cgi_args
{
my ($cgi) = @_;
my ($d) = grep { &virtual_server::can_edit_domain($_) &&
	         $_->{$module_name} } &virtual_server::list_domains();
if ($cgi eq 'edit.cgi') {
	return $d ? 'dom='.$d->{'id'} : 'none';
	}
return undef;
}
