
do '../web-lib.pl';
&init_config();
do '../ui-lib.pl';
&foreign_require("virtual-server", "virtual-server-lib.pl");
%access = &get_module_acl();

$apachemod_lib_cmd = "$module_config_directory/apachemod.pl";
@tracking_services = (
	[ 'account', \&get_analytics_account, \&save_analytics_account,
	  '[A-Za-z0-9\\-]+' ],
	[ 'mybloglog', \&get_mybloglog_account, \&save_mybloglog_account,
	  '\\d+' ],
	[ 'quantcast', \&get_quantcast_account, \&save_quantcast_account,
	  '[A-Za-z0-9\\-]+' ],
	[ 'clicky', \&get_clicky_account, \&save_clicky_account,
	  '[0-9]+' ],
	);

# get_analytics_account(&domain)
# Returns the Google Analytics account ID for a virtual server, by looking
# at the server's PerlSetVar directive.
sub get_analytics_account
{
local ($d) = @_;
return &get_perlsetvar($d, "AnalyticsID");
}

# get_mybloglog_account(&domain)
# Returns the MyBlogLog account ID for a virtual server, by looking
# at the server's PerlSetVar directive.
sub get_mybloglog_account
{
local ($d) = @_;
return &get_perlsetvar($d, "MyBlogLogID");
}

# get_quantcast_account(&domain)
# Returns the Quantcast account ID for a virtual server, by looking
# at the server's PerlSetVar directive.
sub get_quantcast_account
{
local ($d) = @_;
return &get_perlsetvar($d, "QuantcastID");
}

# get_clicky_account(&domain)
# Returns the Clicky account ID for a virtual server, by looking
# at the server's PerlSetVar directive.
sub get_clicky_account
{
local ($d) = @_;
return &get_perlsetvar($d, "ClickyID");
}

# get_perlsetvar(&domain, name)
sub get_perlsetvar
{
local ($d, $name) = @_;
local ($virt, $vconf) = &virtual_server::get_apache_virtual($d->{'dom'},
							    $d->{'web_port'});
if ($virt) {
	local @psv = &apache::find_directive("PerlSetVar", $vconf);
	foreach my $psv (@psv) {
		if ($psv =~ /^\Q$name\E\s+(\S+)/) {
			return $1;
			}
		}
	}
return undef;
}

# save_analytics_account(&domain, account)
# Add or set the PerlSetVar directive use by the Perl filter to generate
# the correct <script> section for Google Analytics.
sub save_analytics_account
{
local ($d, $account) = @_;
return &save_perlsetvar($d, $account, "AnalyticsID");
}

# save_mybloglog_account(&domain, account)
# Adds directives for the MyBlogLog account ID
sub save_mybloglog_account
{
local ($d, $account) = @_;
return &save_perlsetvar($d, $account, "MyBlogLogID");
}

# save_quantcast_account(&domain, account)
# Adds directives for the MyBlogLog account ID
sub save_quantcast_account
{
local ($d, $account) = @_;
return &save_perlsetvar($d, $account, "QuantcastID");
}

# save_clicky_account(&domain, account)
# Adds directives for the Clicky account ID
sub save_clicky_account
{
local ($d, $account) = @_;
return &save_perlsetvar($d, $account, "ClickyID");
}

# save_perlsetvar(&domain, account, name)
sub save_perlsetvar
{
local ($d, $account, $name) = @_;
&virtual_server::require_apache();
local $conf = &apache::get_config();
local @ports = ( $d->{'web_port'} );
push(@ports, $d->{'web_sslport'}) if ($d->{'ssl'});
local $done = 0;
foreach my $p (@ports) {
	local ($virt, $vconf) =
		&virtual_server::get_apache_virtual($d->{'dom'}, $p);
	next if (!$virt);
	&lock_file($virt->{'file'});
	local @psv = &apache::find_directive("PerlSetVar", $vconf);
	local @oldpsv = @psv;
	@psv = grep { !/^\Q$name\E/ } @psv;
	if ($account) {
		push(@psv, "$name $account");
		}
	if (scalar(@psv) || scalar(@oldpsv)) {
		&apache::save_directive("PerlSetVar", \@psv, $vconf, $conf);
		&flush_file_lines($virt->{'file'});
		}
	&unlock_file($virt->{'file'});
	$done++;
	}
if ($done) {
	&virtual_server::register_post_action(\&virtual_server::restart_apache);
	}
return $done;
}

# has_analytics_directives(&domain)
# Checks if some domain has the mod_perl directives needed for analytics
# integration (PerlOutputFilterHandler and PerlRequire)
sub has_analytics_directives
{
local ($d) = @_;
local ($virt, $vconf) = &virtual_server::get_apache_virtual($d->{'dom'},
							    $d->{'web_port'});
local @pof = &apache::find_directive("PerlOutputFilterHandler", $vconf);
@pof = grep { $_ eq "Virtualmin::GoogleAnalytics" } @pof;
return 0 if (!@pof);
local @prq = &apache::find_directive("PerlRequire", $vconf);
@prq = grep { $_ eq "$module_config_directory/apachemod.pl" } @prq;
return 0 if (!@prq);
return 1;
}

1;

1;

