# -*- tab-width : 4; indent-tabs-mode : nil -*-


install_pre_build_native_make()
{
    local make_exe_file="make-85047eb-msvs.exe"

    if [ ! -f "${BASE_DIR?}/packages/${make_exe_file?}" -o ! -x "${BASE_DIR?}/opt/bin/make" ] ; then
        pushd "${BASE_DIR?}/packages" > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
        rm -fr "${make_exe_file?}"
        wget -O "http://dev-www.libreoffice.org/bin/cygwin/${make_exe_file?}" || die "Error download ${module?} source package"
        cp "${make_exe_file?}" "${BASE_DIR?}/opt/bin/make" || die "Error copying make"
        chmod a+x "${BASE_DIR?}/opt/bin/make" || die "Error chmoding installed make"
        popd > /dev/null || die "Error poping ${BASE_DIR?}/packages"
    fi
}

install_build_dep()
{
    install_pre_build_native_make
    install_ant
    install_junit
}
