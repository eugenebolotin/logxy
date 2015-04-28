# -*- Encoding: utf-8 -*-
# kate: space-indent on; indent-width 4; replace-tabs on;
#
Name:           logxy
Version:        1.0
Release:        2.el6

%define         _topdir         %{getenv:PWD}
%define         _builddir       %{_tmppath}
%define         _rpmdir         %{_topdir}/../../RPMS
%define         _sourcedir      %{_topdir}/../
%define         _specdir        %{_topdir}
%define         buildroot       %{_builddir}/%{name}-%{version}.buildroot

Summary:        LogXY is a simple logger daemon that uses ZeroMQ as a transport
License:        MIT
Packager:       Eugene Bolotin <eugenebolotin@yandex.ru>
Group:          Applications/System
Distribution:   Red Hat Enterprise Linux
BuildArch:      x86_64

Source0:        logxy

%description
LogXY is a simple logger daemon that uses ZeroMQ as a transport.

%prep
%__mkdir_p %{name}-%{version}
cp %{_sourcedir}logxy                                   %{name}-%{version}
cp %{_sourcedir}rpm/logxy.init                          %{name}-%{version}

%install
%__mkdir_p $RPM_BUILD_ROOT/opt/logxy
install -m755 -D %{name}-%{version}/logxy               ${RPM_BUILD_ROOT}/opt/logxy/logxy
install -m755 -D %{name}-%{version}/logxy.init          ${RPM_BUILD_ROOT}/etc/init.d/logxy

%files
%attr(0755, nginx, nginx) /opt/logxy/logxy
%attr(0755, nginx, nginx) /etc/init.d/logxy

%clean
%{__rm} -rf $RPM_BUILD_ROOT %{name}-%{version}

%post
/etc/init.d/logxy restart

%changelog
* Mon Apr 27 2015 Eugene Bolotin
- 1.0-2. Spec and init files polished.
* Fri Apr 24 2015 Eugene Bolotin
- 1.0-1. Initial stage: package includes initial version of the scripts.
