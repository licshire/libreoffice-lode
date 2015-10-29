# -*- tab-width : 4; indent-tabs-mode : nil -*-
#
#    Copyright (C) 2014 Norbert Thiebaud
#    License: GPLv3
#

determine_gstreamer()
{
    if [ ! -d /usr/bin/gstreamer-1.0 -a ! -d /usr/lib64/gstreamer-1.0 ] ; then
        if [ -d /usr/bin/gstreamer-0.10 -o -d /usr/lib64/gstreamer-0.10 ] ; then
            extra_autogen="$extra_autogen--enable-gstreamer-0-10
--disable-gstreamer
"
        fi
    fi
}

install_build_dep()
{
    install_generic_conf_make_install "make" "4.1" "http://mirrors.kernel.org/gnu/make" "make-4.1.tar.gz"
    install_generic_conf_make_install "doxygen" "1.8.8" "http://ftp.stack.nl/pub/users/dimitri" "doxygen-1.8.8.src.tar.gz"
    install_ant
    determine_gstreamer
}

os_prereq_centos7()
{
local distro_name="$1"

cat <<EOF

For ${distro_name} you need to install build depencies using 'yum-builddep libreoffice'
For information, as of this writting, the minimum needed packages
to build a vanilla libreoffice (without tweaking the autogen.input file)
are:

required by lode itself:

 gcc-c++
 flex
 bison
 unzip
 autoconf
 automake

 additional packages needed to build libreoffice:
 cups-devel
 fontconfig-devel
 perl-Digest-MD5
 perl-Archive-Zip
 java-1.7.0-openjdk-devel
 gperf
 libxslt-devel
 bzip2
 libX11-devel
 libXt-devel
 libXext-devel
 libXrender-devel
 libXrandr-devel
 patch
 zip
 gtk3-devel
 dbus-glib-devel
 gtk2-devel
 gstreamer1-plugins-base-devel
 glew-devel

Note: this list is for information only. it will become
obsolete over time. using yum-builddep will pull
more package than strictly needed for a vanilla build
but is much more likley to be accurate and maintained.

EOF

}

os_prereq_linux_default()
{
cat <<EOF
On Linux, you need to have installed some build dependencies.
The exactly list and the name of the required packages is distro-dependant

some distro have tools to get all the build dependencies at once

if you have zipper:
zypper si -d libreoffice

if you have yum-builddep
yum-builddep libreoffice

if you have apt-get
apt-get build-dep libreoffice

if you have dnf
dnf builddep libreoffice

EOF
}

os_prereq()
{
    if [ -e /etc/os-release ]; then
        . /etc/os-release
        if [ "$NAME" == "openSUSE" ]; then
            cat << EOF

For openSUSE, you need to install build dependencies using 'zypper si -d libreoffice'
EOF
        elif [ "$NAME" == "CentOS Linux" ]; then
            os_prereq_centos7 "CentOS 7"
        elif [ "$NAME" == "Red Hat Enterprise Linux Server" ]; then
            if [ "$VERSION_ID" = "7.0" ] ; then
                os_prereq_centos7 "RHEL 7"
            else
                os_prereq_linux_default
            fi
        else
            os_prereq_linux_default
        fi
    fi
}

# vim: set et sw=4 ts=4 textwidth=0:
