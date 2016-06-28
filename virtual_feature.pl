# Defines functions for this feature
use strict;
use warnings;
our %text;
our $module_name;
our $apachemod_lib_cmd;

require 'virtualmin-google-analytics-lib.pl';

# feature_name()
# Returns a short name for this feature
sub feature_name
{
return $text{'feat_name'};
}

# feature_losing(&domain)
# Returns a description of what will be deleted when this feature is removed
sub feature_losing
{
return $text{'feat_losing'};
}

# feature_label(in-edit-form)
# Returns the name of this feature, as displayed on the domain creation and
# editing form
sub feature_label
{
my ($edit) = @_;
return $edit ? $text{'feat_label2'} : $text{'feat_label'};
}

sub feature_hlink
{
return "label";
}

# feature_check()
# Returns undef if all the needed programs for this feature are installed,
# or an error message if not
sub feature_check
{
&virtual_server::require_apache();
return $text{'feat_noperl'} if (!$apache::httpd_modules{'mod_perl'});
return $text{'feat_noapache'} if ($apache::httpd_modules{'core'} < 2);
return $text{'feat_nodeflate'} if ($apache::httpd_modules{'mod_deflate'});
eval "use Apache2::Filter";
return &text('feat_nomod', "<tt>Apache2::Filter</tt>") if ($@);
&create_apachemod();
return undef;
}

# feature_depends(&domain, [&old-domain])
# Returns undef if all pre-requisite features for this domain are enabled,
# or an error message if not
sub feature_depends
{
my ($d, $oldd) = @_;
return $text{'feat_edepweb'} if (!$d->{'web'});
if (defined(&virtual_server::list_domain_php_inis) &&
    &foreign_check("phpini") &&
    (!$oldd || !$oldd->{$module_name})) {
	&foreign_require("phpini", "phpini-lib.pl");
	foreach my $ini (&virtual_server::list_domain_php_inis($d)) {
		my $pconf = &phpini::get_config($ini->[1]);
		my $comp = &phpini::find_value(
			"zlib.output_compression", $pconf);
		if (lc($comp) =~ /on|true|yes/) {
			return &text('feat_ezlib',
				     "<tt>zlib.output_compression</tt>",
				     "<tt>$ini->[1]</tt>");
			}
		}
	}
return undef;
}

# feature_clash(&domain, [field])
# Returns undef if there is no clash for this domain for this feature, or
# an error message if so
sub feature_clash
{
# Can never clash, because this is enabled on a per-server basis
return undef;
}

# feature_suitable([&parentdom], [&aliasdom], [&subdom])
# Returns 1 if some feature can be used with the specified alias and
# parent domains
sub feature_suitable
{
my ($parentdom, $aliasdom, $subdom) = @_;
return $aliasdom ? 0 : 1;	# not for alias domains
}

# feature_import(domain-name, user-name, db-name)
# Returns 1 if this feature is already enabled for some domain being imported,
# or 0 if not
sub feature_import
{
my ($dname, $user, $db) = @_;
my $fakedom = { 'dom' => $dname };
return &has_analytics_directives($fakedom);
}

# feature_setup(&domain)
# Called when this feature is added, with the domain object as a parameter
sub feature_setup
{
my ($d) = @_;
&$virtual_server::first_print($text{'feat_setup'});
&virtual_server::obtain_lock_web($_[0])
        if (defined(&virtual_server::obtain_lock_web));

&virtual_server::require_apache();
my $conf = &apache::get_config();
my @ports = ( $d->{'web_port'} );
push(@ports, $d->{'web_sslport'}) if ($d->{'ssl'});
my $done = 0;
foreach my $p (@ports) {
	my ($virt, $vconf) =
		&virtual_server::get_apache_virtual($d->{'dom'}, $p);
	next if (!$virt);

	# Add PerlRequire for apachemod.pl, which sets lib path
	&lock_file($virt->{'file'});
	my @prq = &apache::find_directive("PerlRequire", $vconf);
	push(@prq, $apachemod_lib_cmd);
	&apache::save_directive("PerlRequire", \@prq, $vconf, $conf);

	# Add filter directive
	my @pof = &apache::find_directive("PerlOutputFilterHandler", $vconf);
	push(@pof, "Virtualmin::GoogleAnalytics");
	&apache::save_directive("PerlOutputFilterHandler", \@pof, $vconf,$conf);

	# Add PerlSetVar SSL
	if ($p == $d->{'web_sslport'}) {
		my @psv = &apache::find_directive("PerlSetVar", $vconf);
		@psv = &unique(@psv, "SSL 1");
		&apache::save_directive("PerlSetVar", \@psv, $vconf, $conf);
		}

	&unlock_file($virt->{'file'});
	&flush_file_lines($virt->{'file'});
	$done++;
	}

&virtual_server::release_lock_web($_[0])
        if (defined(&virtual_server::release_lock_web));
if ($done) {
	&virtual_server::register_post_action(\&virtual_server::restart_apache);
	}
else {
	&$virtual_server::second_print($text{'feat_novirt'});
	return 0;
	}

# Create apachemod.pl
&create_apachemod();

&$virtual_server::second_print($virtual_server::text{'setup_done'});
return 1;
}

# feature_modify(&domain, &olddomain)
# Called when a domain with this feature is modified
sub feature_modify
{
# Nothing to do
return 1;
}

# feature_delete(&domain)
# Called when this feature is disabled, or when the domain is being deleted
sub feature_delete
{
my ($d) = @_;
&$virtual_server::first_print($text{'feat_delete'});
&virtual_server::obtain_lock_web($_[0])
        if (defined(&virtual_server::obtain_lock_web));

&virtual_server::require_apache();
my $conf = &apache::get_config();
my @ports = ( $d->{'web_port'} );
push(@ports, $d->{'web_sslport'}) if ($d->{'ssl'});
my $done = 0;
foreach my $p (@ports) {
	my ($virt, $vconf) =
		&virtual_server::get_apache_virtual($d->{'dom'}, $p);
	next if (!$virt);

	# Remove PerlRequire and PerlOutputFilterHandler
	&lock_file($virt->{'file'});
	my @prq = &apache::find_directive("PerlRequire", $vconf);
	my @newprq = grep { $_ ne $apachemod_lib_cmd } @prq;
	&apache::save_directive("PerlRequire", \@newprq,
				$vconf, $conf);
	my @pof = &apache::find_directive("PerlOutputFilterHandler", $vconf);
	my @newpof = grep { $_ ne "Virtualmin::GoogleAnalytics" } @pof;
	&apache::save_directive("PerlOutputFilterHandler", \@newpof,
				$vconf, $conf);

	if (@prq || @pof) {
		&flush_file_lines($virt->{'file'});
		}
	&unlock_file($virt->{'file'});
	$done++;
	}

&virtual_server::release_lock_web($_[0])
        if (defined(&virtual_server::release_lock_web));
if ($done) {
	&virtual_server::register_post_action(\&virtual_server::restart_apache);
	&$virtual_server::second_print($virtual_server::text{'setup_done'});
	}
else {
	&$virtual_server::second_print($text{'feat_novirt'});
	}
}

# feature_webmin(&domain, &other)
# Returns a list of webmin module names and ACL hash references to be set for
# the Webmin user when this feature is enabled
sub feature_webmin
{
my @doms = map { $_->{'dom'} } grep { $_->{$module_name} } @{$_[1]};
if (@doms) {
	return ( [ $module_name,
		   { 'domains' => join(" ", @doms),
		     'noconfig' => 1,
		   } ] );
	}
else {
	return ( );
	}
}

# feature_links(&domain)
# Returns an array of link objects for webmin modules for this feature
sub feature_links
{
my ($d) = @_;
return ( { 'mod' => $module_name,
	   'desc' => $text{'links_link'},
	   'page' => 'edit.cgi?dom='.&urlize($d->{'id'})."&virtualmin=1",
	   'cat' => 'logs',
         } );
}

sub feature_modules
{
return ( [ $module_name, $text{'feat_module'} ] );
}

sub feature_validate
{
my ($d) = @_;
return &has_analytics_directives($d) ? undef : $text{'feat_notvalid'};
}

1;

