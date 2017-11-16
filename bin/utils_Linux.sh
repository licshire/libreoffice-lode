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

install_private_clang()
{
clang_version="$1"

    if [ ! -x "${BASE_DIR?}/opt_private/clang-${clang_version}/bin/clang" -o -f "${BASE_DIR?}/packages/llvm-${clang_version}.src/.lode_building" -o ! -d "${BASE_DIR?}/packages/llvm-${clang_version}.src" ]; then
        rm -fr ${BASE_DIR?}/packages/llvm-${clang_version}*
        pushd "${BASE_DIR?}/packages" > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
        curl -L -O http://llvm.org/releases/${clang_version}/llvm-${clang_version}.src.tar.xz || die "Error downloading llvm source"
        tar -xf "llvm-${clang_version}.src.tar.xz" || die "Error untaring llvm source"
        touch "${BASE_DIR?}/packages/llvm-${clang_version}.src/.lode_building"
        curl -L -O "http://llvm.org/releases/${clang_version}/cfe-${clang_version}.src.tar.xz" || die "Error downloading clang source"
        tar -xf "cfe-${clang_version}.src.tar.xz" -C "llvm-${clang_version}.src/tools" || die "Error untaring clang source"
        mv "llvm-${clang_version}.src/tools/cfe-${clang_version}.src" "llvm-${clang_version}.src/tools/clang" || die "Error ranming clang source directory"
        rm -fr llvmbuild
        mkdir llvmbuild || die "Error creating the llvm build directory"
        pushd "${BASE_DIR?}/packages/llvmbuild" || die "Error switching to ${BASE_DIR?}/packages/llvmbuild"
        ${BASE_DIR?}/opt/lode_private/bin/cmake -DCMAKE_INSTALL_PREFIX=${BASE_DIR?}/opt_private/clang-${clang_version} -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="host" ../llvm-${clang_version}.src || die "Error configuring llvm"
        make -j $(getconf _NPROCESSORS_ONLN) || die "Error building llvm"
        make install || die "Error installing llvm"
        rm "${BASE_DIR?}/packages/llvm-${clang_version}.src/.lode_building"
        popd > /dev/null
        popd > /dev/null
    fi
}

install_clang_format()
{
clang_format_version="$1"

    if [ ! -x "${BASE_DIR?}/opt/bin/clang-format" ]; then
        pushd "${BASE_DIR?}/packages" > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
        curl -L -O "http://dev-www.libreoffice.org/bin/clang-format-${clang_format_version}-linux64" || die "Error downloading clang format"
        mv "clang-format-${clang_format_version}-linux64" "${BASE_DIR?}/opt/bin/clang-format" || die "Error renaming clang-format"
        chmod +x "${BASE_DIR?}/opt/bin/clang-format" || die "Error marking clang-format as executable"
        popd > /dev/null
    fi
}

install_build_dep()
{
local inst
local version

    install_generic_conf_make_install "make" "4.1" "http://mirrors.kernel.org/gnu/make" "make-4.1.tar.gz"
    inst="$(type -p doxygen)"
    if [ -n "$inst" ] ; then
        version="$(doxygen --version)"
    fi
    if [ -z "$inst" -o "$(compare_version "$version" "1.8.10")" = "-1" ] ; then
        version=
        inst="$(type -p cmake)"
        if [ -n "$inst" ] ; then
            version="$(cmake --version | sed -e "s/.* //")"
        fi
        if [ -z "$inst" -o "$(compare_version "$version" "3.3.1")" = "-1" ] ; then
            install_private_cmake "3.3.1" "http://www.cmake.org/files/v3.3/" "cmake-3.3.1.tar.gz"
        fi
        install_doxygen "1.8.10" "http://ftp.stack.nl/pub/users/dimitri" "doxygen-1.8.10.src.tar.gz"
    else
        if [ ! -x "${BASE_DIR?}/opt/bin/doxygen" ] ; then
            ln -s "$inst" "${BASE_DIR?}/opt/bin/doxygen"
        fi
    fi
    if [ "$DO_JENKINS" = "1" ] ; then
        version=
        inst="$(type -p cmake)"
        if [ -n "$inst" ] ; then
            version="$(cmake --version | sed -e "s/.* //")"
        fi
        if [ -z "$inst" -o "$(compare_version "$version" "3.3.1")" = "-1" ] ; then
            install_private_cmake "3.3.1" "http://www.cmake.org/files/v3.3/" "cmake-3.3.1.tar.gz"
        fi
        install_generic_conf_make_install "ccache" "3.2.5" "https://www.samba.org/ftp/ccache" "ccache-3.2.5.tar.xz"
        install_clang_format "5.0.0"
        install_private_clang "3.8.0"
    fi
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
