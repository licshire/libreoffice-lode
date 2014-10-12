

install_ant()
{
    local ant_version=apache-ant-1.9.4

    if [ ! -x "${BASE_DIR?}/opt/bin/ant" ] ; then
	pushd "${BASE_DIR?}/packages" > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
	rm -fr "${BASE_DIR?}/packages/${ant_version?}"
	rm -f "${BASE_DIR?}/packages/${ant_version?}-bin.zip"
	curl -O http://archive.apache.org/dist/ant/binaries/${ant_version?}-bin.zip || die "Error downloading ant"
	unzip ${ant_version?}-bin.zip || die "Error unziping ant"
	ln -s "${BASE_DIR?}/packages/${ant_version?}/bin/ant" "${BASE_DIR}/opt/bin/ant" || die "Error soft-linking ant"
	echo "ant Installed" 1>&2
    else
	echo "ant already installed" 1>&2
    fi
    
}

install_default_autogen_input()
{
    cat > "${BASE_DIR?}/autogen.input.base" <<EOF
--with-junit=${BASE_DIR?}/opt/share/java/junit.jar
--with-external-tar=${BASE_DIR?}/ext_tar
EOF
}

install_junit()
{
    if [ -f "${BASE_DIR?}/opt/share/java/junit.jar" ] ; then
	echo "junit Already Installed" 1>&2
    else
	test_create_dirs "${BASE_DIR?}/opt/share" "${BASE_DIR?}/opt/share/java"
	curl -o "${BASE_DIR?}/opt/share/java/junit.jar" -O#L "https://github.com/downloads/junit-team/junit/junit-4.11.jar" || die "Error downloading junit"
	echo "junit Installed" 1>&2
    fi
}

install_build_dep()
{
    install_generic_conf_make_install "autoconf" "2.69" "http://mirrors.kernel.org/gnu/autoconf" "autoconf-2.69.tar.gz"
    install_generic_conf_make_install "automake" "1.14" "http://mirrors.kernel.org/gnu/automake" "automake-1.14.tar.gz"
    install_generic_conf_make_install "make" "4.1" "http://mirrors.kernel.org/gnu/make" "make-4.1.tar.gz"
    install_ant
    install_junit
    install_generic_conf_make_install "doxygen" "1.8.8" "http://ftp.stack.nl/pub/users/dimitri" "doxygen-1.8.8.src.tar.gz"
    install_generic_conf_make_install "ccache" "3.1.9" "http://www.samba.org/ftp/ccache" "ccache-3.1.9.tar.gz"
    install_default_autogen_input
}

os_flavor_notes()
{
cat <<EOF
=============

Add ${BASE_DIR}/opt/bin in front of your PATH before configuring or building libreoffice

When configuring LibreOffice you will need to add:
--with-junit=${BASE_DIR}/opt/share/java/junit.jar

EOF
}