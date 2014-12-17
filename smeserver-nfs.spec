# $Id: smeserver-nfs.spec,v 1.1 2013/03/03 05:41:38 unnilennium Exp $
# Authority: slords
# Name: Shad L. Lords

Summary: smeserver - configure nfs server
%define name smeserver-nfs
Name: %{name}
%define version 1.2.0
%define release 7
Version: %{version}
Release: %{release}%{?dist}
License: GPL
Group: Networking/Daemons
Source: %{name}-%{version}.tar.gz
BuildRoot: /var/tmp/%{name}-%{version}-%{release}-buildroot
Requires: e-smith-base
Requires: smeserver-release >= 9
Requires: nfs-utils
Requires: nfs4-acl-tools
Requires: e-smith-lib 
Requires: e-smith-packetfilter 
BuildRequires: e-smith-devtools
BuildArchitectures: noarch

%description
e-smith server and gateway - configure nfs server

%changelog
* Mon Dec 15 2014 stephane de Labrusse <stephdl@de-labrusse.fr> 1.2.0-7.sme
- added a default db nfs-rules
- added an exception if nfs-rules is removed by the admin
 
* Mon Dec 15 2014 stephane de Labrusse <stephdl@de-labrusse.fr> 1.2.0-6.sme
- Added an event nfs-conf shorter for the server-manager
- Added a template /etc/exports/20CustomRules for manual settings

* Sun Dec 7 2014 stephane de Labrusse <stephdl@de-labrusse.fr> 1.2.0-5.sme
- added a template of hosts.allow
- added restart nfslock/rpcbind to remoteaccess-update & nfs-update
- display Group description and permissions from ibay account in nfs panel
- added a textarea box for ip of nfsclient
- display status of nfs share in the main panel

* Sat Dec 6 2014 stephane de Labrusse <stephdl@de-labrusse.fr> 1.2.0-4.sme
- Added a panel with en-us locale and validator

* Tue Nov 25 2014 stephane de Labrusse <stephdl@de-labrusse.fr> 1.2.0-3.sme
- Added nfs4-acl-tools for nfsv4 dependency
- Added a template to /etc/exports
- Added a specific event nfs-update

* Mon Nov 24 2014 stephane de Labrusse <stephdl@de-labrusse.fr> 1.2.0-2.sme
- removed portmap to rpcbind in r7.d

* Tue Sep 16 2014 stephane de Labrusse <stephdl@de-labrusse.fr> 1.2.0-1.sme
- Initial release to sme9

* Sun Apr 29 2007 Shad L. Lords <slords@mail.com>
- Clean up spec so package can be built by koji/plague

* Thu Dec 07 2006 Shad L. Lords <slords@mail.com>
- Update to new release naming.  No functional changes.
- Make Packager generic

* Mon Jan 30 2006 Shad L. Lords <slords@mail.com>
- initial

%prep
%setup

%build
perl createlinks

%install
rm -rf $RPM_BUILD_ROOT
(cd root   ; find . -depth -print | cpio -dump $RPM_BUILD_ROOT)
rm -f %{name}-%{version}-%{release}-filelist
/sbin/e-smith/genfilelist $RPM_BUILD_ROOT \
    > %{name}-%{version}-%{release}-filelist
echo "%doc COPYING" >> %{name}-%{version}-%{release}-filelist

%postun

%clean 
rm -rf $RPM_BUILD_ROOT

%files -f %{name}-%{version}-%{release}-filelist
%defattr(-,root,root)

