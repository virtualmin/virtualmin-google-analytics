
BEGIN { push(@INC, ".."); };
eval "use WebminCore;";
if ($@) {
	do '../web-lib.pl';
	do '../ui-lib.pl';
	}
&init_config();
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
	[ 'woopra', \&get_woopra_account, \&save_woopra_account,
	  '[A-Za-z0-9\\-]+' ],
	[ 'piwik', \&get_piwik_account, \&save_piwik_account,
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

# get_woopra_account(&domain)
# Returns the Woopra account name for a virtual server, by looking
# at the server's PerlSetVar directive. Not actually used in the JS though.
sub get_woopra_account
{
local ($d) = @_;
return &get_perlsetvar($d, "WoopraID");
}

# get_piwik_account(&domain)
# Returns the Piwik site ID for a virtual server, by looking
# at the server's PerlSetVar directive.
sub get_piwik_account
{
local ($d) = @_;
return &get_perlsetvar($d, "PiwikID");
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

# save_woopra_account(&domain, account)
# Adds directives for the Woopra account name
sub save_woopra_account
{
local ($d, $account) = @_;
return &save_perlsetvar($d, $account, "WoopraID");
}

# save_piwik_account(&domain, account)
# Adds directives for the Piwik site ID
sub save_piwik_account
{
local ($d, $account) = @_;
return &save_perlsetvar($d, $account, "PiwikID");
}

# save_perlsetvar(&domain, account, name)
sub save_perlsetvar
{
local ($d, $account, $name) = @_;
&virtual_server::obtain_lock_web($d)
        if (defined(&virtual_server::obtain_lock_web));
&virtual_server::require_apache();
local $conf = &apache::get_config();
local @ports = ( $d->{'web_port'} );
push(@ports, $d->{'web_sslport'}) if ($d->{'ssl'});
local $done = 0;
foreach my $p (@ports) {
	local ($virt, $vconf) =
		&virtual_server::get_apache_virtual($d->{'dom'}, $p);
	next if (!$virt);
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
	$done++;
	}
&virtual_server::release_lock_web($d)
        if (defined(&virtual_server::release_lock_web));
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

# get_piwik_default_url(&domain)
# Returns the default piwik URL. This is keyed off the top-level domain
sub get_piwik_default_url
{
local ($d) = @_;
local $parent = $d->{'parent'} ? &virtual_server::get_domain($d->{'parent'})
			       : $d;
return $parent->{'piwik_url'};
}

# save_piwik_default_url(&domain, url)
# Set the piwik default base URL
sub save_piwik_default_url
{
local ($d, $url) = @_;
local $parent = $d->{'parent'} ? &virtual_server::get_domain($d->{'parent'})
			       : $d;
$parent->{'piwik_url'} = $url;
&virtual_server::save_domain($parent);
}

1;

1;

