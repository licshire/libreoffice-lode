

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

install_autoconf()
{
    local autoconf_version=autoconf-2.54
    if [ ! -x "${BASE_DIR?}/opt/bin/autoconf" ] ; then
	pushd "${BASE_DIR?}/packages" > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
	rm -fr "${BASE_DIR?}/packages/${autoconf_version?}"
	rm -f "${BASE_DIR?}/packages/${autoconf_version?}.tar.gz"
	curl -O http://mirrors.kernel.org/gnu/autoconf/${autoconf_version?}.tar.gz || die "Error download autoconf source package"
	tar -xf ${autoconf_version?}.tar.gz || die "Error untaring autoconf source"
	pushd ${autoconf_version?} > /dev/null
	./configure --prefix=${BASE_DIR}/opt || die "Error configuring autoconf"
	make || die "error building autoconf"
	make install || die "error installing autoconf"
	popd > /dev/null
	popd > /dev/null
	echo "autoconf Installed" 1>&2
    else
	echo "autoconf already installed" 1>&2
    fi
}

install_automake()
{
    local automake_version=automake-1.11

    if [ ! -x "${BASE_DIR?}/opt/bin/automake" ] ; then
	pushd "${BASE_DIR?}/packages" > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
	rm -fr "${BASE_DIR?}/packages/${automake_version?}"
	rm -f "${BASE_DIR?}/packages/${automake_version?}.tar.gz"
	curl -O http://mirrors.kernel.org/gnu/automake/${automake_version?}.tar.gz || die "Error download automake source package"
	tar -xf ${automake_version?}.tar.gz || die "Error untaring automake source"
	pushd ${automake_version?} > /dev/null
	./configure --prefix=${BASE_DIR}/opt || die "Error configuring automake"
	make || die "error building automake"
	make install || die "error installing automake"
	popd > /dev/null
	popd > /dev/null
	echo "automake Installed" 1>&2
    else
	echo "automake already installed" 1>&2
    fi

}

install_doxygen()
{
    local doxygen_version=doxygen-1.8.8

    if [ ! -x "${BASE_DIR?}/opt/bin/doxygen" ] ; then
	pushd "${BASE_DIR?}/packages" > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
	rm -fr "${BASE_DIR?}/packages/${doxygen_version?}"
	rm -f "${BASE_DIR?}/packages/${doxygen_version?}.src.tar.gz"
	curl -O http://ftp.stack.nl/pub/users/dimitri/${doxygen_version?}.src.tar.gz || die "Error download doxygen source package"
	tar -xf ${doxygen_version?}.src.tar.gz || die "Error untaring doxygen source"
	pushd ${doxygen_version?} > /dev/null
	./configure --prefix=${BASE_DIR}/opt || die "Error configuring doxygen"
	make || die "error building doxygen"
	make install || die "error installing doxygen"
	popd > /dev/null
	popd > /dev/null
	echo "doxygen Installed" 1>&2
    else
	echo "doxygen already installed" 1>&2
    fi

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

install_make()
{
    local make_version=make-4.1
    if [ ! -x "${BASE_DIR?}/opt/bin/make" ] ; then
	pushd "${BASE_DIR?}/packages" > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
	rm -fr "${BASE_DIR?}/packages/${make_version?}"
	rm -f "${BASE_DIR?}/packages/${make_version?}.tar.gz"
	curl -O http://mirrors.kernel.org/gnu/make/${make_version?}.tar.gz || die "Error download make source package"
	tar -xf ${make_version?}.tar.gz || die "Error untaring make source"
	pushd ${make_version?} > /dev/null
	./configure --prefix=${BASE_DIR}/opt || die "Error configuring make"
	make || die "error building make"
	make install || die "error installing make"
	popd > /dev/null
	popd > /dev/null
	echo "make Installed" 1>&2
    else
	echo "make already installed" 1>&2
    fi
}

install_build_dep()
{
    install_autoconf
    install_automake
    install_make
    install_ant
    install_junit
    install_doxygen
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