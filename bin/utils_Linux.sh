# -*- tab-width : 4; indent-tabs-mode : nil -*-

install_default_autogen_input()
{
    cat > "${BASE_DIR?}/autogen.input.base" <<EOF
--with-external-tar=${BASE_DIR?}/ext_tar
--with-ant-home=${BASE_DIR?}/opt/ant
${extra_autogen}
EOF
}

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
    install_default_autogen_input
}

EOF
