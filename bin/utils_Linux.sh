
get_remote_file()
{
    local url="$1"
    local f="$2"

    if [ -n "$f" ] ; then
	wget -O ${f?} ${url?} || die "Error download ${module?} source package"
    else
wget ${url?} || die "Error download ${module?} source package"
    fi
}

install_default_autogen_input()
{
    cat > "${BASE_DIR?}/autogen.input.base" <<EOF
EOF
--with-external-tar=${BASE_DIR?}/ext_tar
EOF
}

install_build_dep()
{
    install_generic_conf_make_install "make" "4.1" "http://mirrors.kernel.org/gnu/make" "make-4.1.tar.gz"
    install_generic_conf_make_install "doxygen" "1.8.8" "http://ftp.stack.nl/pub/users/dimitri" "doxygen-1.8.8.src.tar.gz"
    install_default_autogen_input
}

EOF
