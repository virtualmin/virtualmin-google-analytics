use strict;
use warnings;

do 'virtualmin-google-analytics-lib.pl';

sub module_install
{
&create_apachemod();
}

