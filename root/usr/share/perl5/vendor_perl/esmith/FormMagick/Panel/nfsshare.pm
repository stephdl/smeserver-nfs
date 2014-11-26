#!/usr/bin/perl -w 

#
# $Id: ibays.pm,v 1.8 2005/09/06 05:49:52 apc Exp $
#

package    esmith::FormMagick::Panel::nfsshare;

use strict;

use esmith::FormMagick;
use esmith::AccountsDB;
use esmith::ConfigDB;
use esmith::DomainsDB;
use esmith::cgi;
use esmith::util;
use File::Basename;
use Exporter;
use Carp;

our @ISA = qw(esmith::FormMagick Exporter);

our @EXPORT = qw(
    print_ibay_table
    print_ibay_name_field
    print_vhost_message
    max_ibay_name_length
    handle_ibays
    print_save_or_add_button
    wherenext
    validate_up_post
);

our $VERSION = sprintf '%d.%03d', q$Revision: 1.8 $ =~ /: (\d+).(\d+)/;

our $accountdb = esmith::AccountsDB->open();
our $configdb = esmith::ConfigDB->open();

=pod 

=head1 NAME

esmith::FormMagick::Panels::ibays - useful panel functions 

=head1 SYNOPSIS

    use esmith::FormMagick::Panels::ibays;

    my $panel = esmith::FormMagick::Panel::ibays->new();
    $panel->display();

=head1 DESCRIPTION

=head2 new();

Exactly as for esmith::FormMagick

=begin testing

$ENV{ESMITH_ACCOUNT_DB} = "10e-smith-base/accounts.conf";
$ENV{ESMITH_CONFIG_DB} = "10e-smith-base/configuration.conf";
$ENV{ESMITH_DOMAINS_DB} = "10e-smith-base/domains.conf";

use_ok('esmith::FormMagick::Panel::ibays');
use vars qw($panel);
ok($panel = esmith::FormMagick::Panel::ibays->new(), 
    "Create panel object");
isa_ok($panel, 'esmith::FormMagick::Panel::ibays');

{ package esmith::FormMagick::Panel::ibays;
  our $accountdb;
  ::isa_ok($accountdb, 'esmith::AccountsDB');
}

=end testing

=cut

sub new 
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = esmith::FormMagick::new($class);
    $self->{calling_package} = (caller)[0];

    return $self;
}

=head1 HTML GENERATION ROUTINES

Routines for generating chunks of HTML needed by the panel.

=head1 ROUTINES FOR FILLING IN FIELDS

=head2 print_ibay_table

Prints out the ibay table on the front page.

=for testing
my $self = esmith::FormMagick::Panel::ibays->new();
$self->{cgi} = CGI->new("");
can_ok('main', 'print_ibay_table');
$self->print_ibay_table();
like($_STDOUT_, qr/NAME/, "Found NAME header in table output");
#like($_STDOUT_, qr/testibay/, "Found test ibay in user table output");
#like($_STDOUT_, qr/ff0000/, "Found red 'reset password' output");

=cut

sub print_ibay_table {
    my $self = shift;
    my $q = $self->{cgi};
    my $name        = $self->localise('NAME');
    my $description = $self->localise('DESCRIPTION');
    my $modify      = $self->localise('MODIFY');
    my $action_h    = $self->localise('ACTION');
    
    my @ibays = $accountdb->ibays();

    unless ( scalar @ibays )
    {
        print $q->Tr($q->td($self->localise('NO_IBAYS')));
        return "";
    }

    print $q->start_table({-CLASS => "sme-border"}),"\n";
    print $q->Tr (
                  esmith::cgi::genSmallCell($q, $name,"header"),
                  esmith::cgi::genSmallCell($q, $description,"header"),
                  esmith::cgi::genSmallCell($q, $action_h,"header", 3)),"\n";
    my $scriptname = basename($0);

    foreach my $i (@ibays) 
    {
        my $ibayname = $i->key();
        my $ibaydesc = $i->prop('Name');

        my $modifiable = $i->prop('Modifiable') || 'yes';


        my $params = $self->build_ibay_cgi_params($ibayname, $i->props());


        my $href = "$scriptname?$params&action=modify&wherenext=";

        my $actionModify = '&nbsp;';
        if ($modifiable eq 'yes')
        {
	    $actionModify .= $q->a({href => "${href}CreateModify"},$modify)
                      . '&nbsp;';
        }

 
        print $q->Tr (
            esmith::cgi::genSmallCell($q, $ibayname,"normal"),
            esmith::cgi::genSmallCell($q, $ibaydesc,"normal"),
            esmith::cgi::genSmallCell($q, $actionModify,"normal"));
    }

    print $q->end_table,"\n";

    return "";
}

sub build_ibay_cgi_params {
    my ($self, $ibayname, %oldprops) = @_;

    #$oldprops{'description'} = $oldprops{Name};
    #delete $oldprops{Name};

    my %props = (
        page    => 0,
        page_stack => "",
        #".id"         => $self->{cgi}->param('.id') || "",
        name => $ibayname,
        #%oldprops
    );

    return $self->props_to_query_string(\%props);
}

*wherenext = \&CGI::FormMagick::wherenext;
sub print_ibay_name_field {
    my $self = shift;
    my $in = $self->{cgi}->param('name') || '';
    my $action = $self->{cgi}->param('action') || '';
    my $maxLength = $configdb->get('maxIbayNameLength')->value;
    print qq(<tr><td colspan="2">) . $self->localise('NAME_FIELD_DESC',
        {maxLength => $maxLength}) . qq(</td></tr>);
    print qq(<tr><td class="sme-noborders-label">) . 
        $self->localise('NAME_LABEL') . qq(</td>\n);
    if ($action eq 'modify' and $in) {
        print qq(
            <td class="sme-noborders-content">$in 
            <input type="hidden" name="name" value="$in">
            <input type="hidden" name="action" value="modify">
            </td>
        );

        # Read the values for each field from the accounts db and store
        # them in the cgi object so our form will have the correct 
        # info displayed.
        my $q = $self->{cgi};
        my $rec = $accountdb->get($in);
        if ($rec)
        {
            $q->param(-name=>'description',-value=>
                $rec->prop('Name'));
            $q->param(-name=>'nfsstatus',-value=>
                ($rec->prop('NfsStatus')));
            $q->param(-name=>'nfsclient',-value=>
                ($rec->prop('NfsClient'))); 
            $q->param(-name=>'nfsrw',-value=>
                ($rec->prop('NfsRW')));  
            $q->param(-name=>'nfssync',-value=>
                ($rec->prop('NfsSync'))); 
            $q->param(-name=>'nfswdelay',-value=>
                ($rec->prop('NfsWdelay'))); 
            $q->param(-name=>'nfssquash',-value=>
                ($rec->prop('NfsSquash')));  
            $q->param(-name=>'nfsanonuid',-value=>
                ($rec->prop('NfsAnonUid'))); 
            $q->param(-name=>'nfsanongid',-value=>
                ($rec->prop('NfsAnonGid')));    
        }
    } else {
        print qq(
            <td><input type="text" name="name" value="$in">
            <input type="hidden" name="action" value="create">
            </td>
        );
    }

    print qq(</tr>\n);
    return undef;

}


=pod

=head2 print_vhost_message()

Prints a warning message that vhosts whose content is this ibay will be
modified to point to primary site.

=for testing
$panel->{cgi} = CGI->new();
$panel->{cgi}->param(-name=>'name', -value=>'bar');
is($panel->print_vhost_message(), undef, 'print_vhost_message');

=cut

sub print_vhost_message {
    my $self = shift;
    my $q = $self->{cgi};
    my $name = $q->param('name');

    my $domaindb = esmith::DomainsDB->open();
    my @domains = $domaindb->get_all_by_prop(Content => $name);
    my $vhostListItems = join "\n",
        (map ($q->li($_->key." ".$_->prop('Description')),
        @domains));
    if ($vhostListItems)
    {
        print $self->localise('VHOST_MESSAGE', {vhostList => $vhostListItems});
    }
    return undef;
}

=head2 group_list()

Returns a hash of groups for the Create/Modify screen's group field's
drop down list.

=for testing
can_ok('main', 'group_list');
my $g = group_list();
is(ref($g), 'HASH', "group_list returns a hashref");
is($g->{simpsons}, "Simpsons Family (simpsons)",
    "Found names and descriptions");

=cut


=head1 THE ROUTINES THAT ACTUALLY DO THE WORK

=for testing
can_ok('main', 'handle_ibays');

=cut

sub handle_ibays {
    my ($self) = @_;
    

    if ($self->cgi->param("action") eq "create") {
        $self->create_ibay();
    } else {
        $self->modify_ibay();
    }
}

=head2 print_save_or_add_button()
=cut

sub print_save_or_add_button {
    my ($self) = @_;

    my $action = $self->cgi->param("action") || '';
    if ($action eq "modify") {
        $self->print_button("SAVE");
    } else {
        $self->print_button("ADD");
    }

}


sub modify_ibay {
    my ($self) = @_;
    my $name = $self->cgi->param('name');
    if (my $acct = $accountdb->get($name)) {
        if ($acct->prop('type') eq 'ibay') {
            $acct->merge_props(
                NfsStatus         => $self->cgi->param('nfsstatus'),
                NfsClient  => $self->cgi->param('nfsclient'),   
                NfsRW   => $self->cgi->param('nfsrw'),
                NfsSync   => $self->cgi->param('nfssync'), 
                NfsWdelay     => $self->cgi->param('nfswdelay'),    
                NfsSquash   => $self->cgi->param('nfssquash'), 
                NfsAnonUid     => $self->cgi->param('nfsanonuid'), 
                NfsAnonGid     => $self->cgi->param('nfsanongid'),
             );

            # Untaint $name before use in system()
            $name =~ /(.+)/; $name = $1;
            if (system ("/sbin/e-smith/signal-event", "nfs-update", 
                $name) == 0) 
            {
                $self->success("SUCCESSFULLY_MODIFIED_IBAY");
            } else {
                $self->error("ERROR_WHILE_MODIFYING_IBAY");
            }
        } else {
            $self->error('CANT_FIND_IBAY');
        }
    } else {
        $self->error('CANT_FIND_IBAY');
    }
}


1;


