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

os_prereq()
{
    if [ -e /etc/os-release ]; then
        . /etc/os-release
        if [ "$NAME" == "openSUSE" ]; then
            cat << EOF

For openSUSE, you need to install build dependencies using 'zypper si -d libreoffice'
EOF
        fi
    fi
}

# vim: set et sw=4 ts=4 textwidth=0:
