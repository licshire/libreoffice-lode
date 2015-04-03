# -*- tab-width : 4; indent-tabs-mode : nil -*-
#
#    Copyright (C) 2014 Norbert Thiebaud
#    License: GPLv3
#


install_default_autogen_input()
{
:
}

install_build_dep()
{
    install_generic_conf_make_install "autoconf" "2.69" "http://mirrors.kernel.org/gnu/autoconf" "autoconf-2.69.tar.gz"
    install_generic_conf_make_install "automake" "1.14" "http://mirrors.kernel.org/gnu/automake" "automake-1.14.tar.gz"
    install_generic_conf_make_install "make" "4.1" "http://mirrors.kernel.org/gnu/make" "make-4.1.tar.gz"
    install_ant
    install_junit
    install_generic_conf_make_install "doxygen" "1.8.9.1" "http://ftp.stack.nl/pub/users/dimitri" "doxygen-1.8.9.1.src.tar.gz"
    install_generic_conf_make_install "ccache" "3.1.9" "https://www.samba.org/ftp/ccache" "ccache-3.1.9.tar.gz"
    install_default_autogen_input
}

os_flavor_notes()
{
if [ -z "$(echo "$PATH" | grep "${BASE_DIR}/opt/bin")" ] ; then
    cat <<EOF
=============

    Add ${BASE_DIR}/opt/bin in front of your PATH before configuring
    or building libreoffice

EOF
fi
}
