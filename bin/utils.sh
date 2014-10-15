# -*- tab-width : 4; indent-tabs-mode : nil -*-
#
# Display an error message and exit
#
die()
{
    echo  "$@"
    exit 1;
}

test_create_dir()
{
    local d="$1"

    if [ -n "${d}" ] ; then
        echo -n "Check directory '$d' ... : "
        if [ -e "${d}" ] ; then
            if [ -d "${d}" ] ; then
                echo "Exist" 1>&2
            else
                echo "Error Exist but not a Directory" 1>&2
                exit 1
            fi
        else
            mkdir "${d}"
            if [ $? = "0" ] ; then
                echo "Created" 1>&2
            else
                echo "Error Creating" 1>&2
                exit 1
            fi
        fi
    fi
}


test_create_dirs()
{
    local d=

    for d in "$@" ; do
        test_create_dir "${d}"
    done
}

test_git_or_clone()
{
    # test if a git repo exist, if not clone it
    # you need to have the current working dir be where you want to clone
    local g="$1"
    local remote="$2"

    if [ -n "${g}" -a -n "${remote}" ] ; then
        if [ -d "${g}" ] ; then
            if [ -d "${g}/.git" ] ; then
                echo "git repo '$(pwd)/$g' exist" 1>&2
            else
                echo "Error $(pwd)/${g} is a directory but not a git repo" 1>&2
                exit 1
            fi
        elif [ -e "${g}" ] ; then
            echo "Error $(pwd)/${g} is a directory but not a git repo" 1>&2
            exit 1
        else
            git clone "${remote}" "${g}"
            if [ $? = "0" ] ; then
                echo "Cloned $(pwd)/${g}" 1>&2
            else
                echo "Error Cloning $(pwd)/${g}" 1>&2
                rm -fr "${g}"
                exit 1
            fi
        fi
    fi
}

test_git_or_bare_mirror()
{
    # test if a git repo exist, if not clone it
    # you need to have the current working dir be where you want to clone
    local g="$1"
    local remote="$2"

    if [ -n "${g}" -a -n "${remote}" ] ; then
        if [ -d "${g}.git" ] ; then
            if [ -f "${g}.git/HEAD" ] ; then
                echo "git repo '$(pwd)/$g.git' exist" 1>&2
            else
                echo "Error $(pwd)/${g}.git is a directory but not a git repo" 1>&2
                exit 1
            fi
        else
            git clone --bare --mirror "${remote}" "${g}.git"
            if [ $? = "0" ] ; then
                echo "Cloned mirror $(pwd)/${g}.git" 1>&2
            else
                echo "Error Cloning mirror $(pwd)/${g}.git" 1>&2
                rm -fr "${g}.git"
                exit 1
            fi
        fi
    fi
}

test_git_or_mirror_clone()
{
    # test if a git repo exist, if not clone it, using a reference mirror if available
    # you need to have the current working dir be where you want to clone
    local g="$1"
    local remote="$2"

    if [ -n "${g}" -a -n "${remote}" ] ; then
        if [ -d "${g?}" ] ; then
            if [ -d "${g?}/.git" ] ; then
                echo "git repo '$(pwd)/${g?}' exist" 1>&2
            else
                echo "Error $(pwd)/${g?} is a directory but not a git repo" 1>&2
                exit 1
            fi
        elif [ -e "${g}" ] ; then
            echo "Error $(pwd)/${g?} is a directory but not a git repo" 1>&2
            exit 1
        else
            if [ -d "${BASE_DIR?}/mirrors/${g?}.git" ] ; then
                git clone --reference "${BASE_DIR?}/mirrors/${g?}.git" "${remote?}" "${g?}"
            else
                git clone "${remote?}" "${g?}"
            fi
            if [ $? = "0" ] ; then
                echo "Cloned $(pwd)/${g?}" 1>&2
            else
                echo "Error Cloning $(pwd)/${g?}" 1>&2
                rm -fr "${g}"
                exit 1
            fi
        fi
    fi
}

install_generic_conf_make_install()
{
    local module="$1"
    local version="$2"
    local base_url="$3"
    local fn="$4"

    if [ -z "${module}" -o -z "${version}" -o -z "${base_url}" -o -z "${fn}" ] ; then
        die "Mssing/Invalid parameter to install_generic_conf_make_install()"
    fi
    if [ ! -x "${BASE_DIR?}/opt/bin/${module?}" -o ! -d "${BASE_DIR?}/packages/${module?}-${version?}" ] ; then
        pushd "${BASE_DIR?}/packages" > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
        rm -fr "${BASE_DIR?}/packages/${module?}-${version?}"
        rm -f "${BASE_DIR?}/packages/${fn?}"
        get_remote_file ${base_url?}/${fn?}
        tar -xf ${fn?} || die "Error untaring ${module?} source"
        pushd ${module?}-${version?} > /dev/null
        ./configure --prefix=${BASE_DIR}/opt || die "Error configuring ${module?}"
        make || die "error building ${module?}"
        make install || die "error installing ${module?}"
        popd > /dev/null
        popd > /dev/null
        echo "${module?} Installed" 1>&2
    else
        echo "${module?} already installed" 1>&2
    fi
}

determin_os_flavor()
{
    OS_FLAVOR="Unknown"
}

os_flavor_notes()
{
:
}

os_notes()
{
:
}

os_prereq()
{
:
}

os_flavor_prereq()
{
:
}

determine_os()
{
    base_os=$(uname)

    case "$base_os" in
    Darwin)
        OS="MacOSX"
        ;;
    Linux)
        OS="Linux"
        ;;
    CYGWIN*)
        OS="Cygwin"
        ;;
    *)
        die "Error:Unsupported base_os:${base_os}"
        ;;
    esac
    OS_FLAVOR=""

    if [ -f "${BASE_DIR?}/bin/utils_${OS?}.sh" ] ; then
        source "${BASE_DIR?}/bin/utils_${OS?}.sh"
    fi
    determine_os_flavor
    if [ -n "${OS_FLAVOR?}" ] ; then
        if [ -f "${BASE_DIR?}/bin/utils_${OS?}_${OS_FLAVOR?}.sh" ] ; then
            source "${BASE_DIR?}/bin/utils_${OS?}_${OS_FLAVOR?}.sh"
        fi
    fi
}

setup_base_tree()
{
    test_create_dirs packages opt ext_tar adm tb
}

setup_adm_repos()
{
    pushd "${BASE_DIR?}/adm" > /dev/null

    test_git_or_clone buildbot git://gerrit.libreoffice.org/buildbot

    popd > /dev/null
}

setup_mirrors()
{
    pushd "${BASE_DIR?}" > /dev/null
    test_create_dirs mirrors
    pushd mirrors > /dev/null || die "Error switching to mirrors"
    test_git_or_bare_mirror core git://gerrit.libreoffice.org/core
    popd > /dev/null
    popd > /dev/null
}
setup_jenkins_slave()
{
    setup_mirrors
    test_create_dirs jenkins
}

write_ssh_config()
{
            cat >> ~/.ssh/config <<EOF

Host lode
Hostname gerrit.libreoffice.org
Port 29418

EOF

}

setup_ssh_config()
{
    local conf_host=""

    if [ -f ~/.ssh/config ] ; then
        conf_host=$(grep '^Host lode$' ~/.ssh/config)
        if [ "${conf_host?}" = "Host lode" ] ; then
            echo "Host lode already present in ~/.ssh/config" 1>&2
        else
            write_ssh_config
        fi
    else
        write_ssh_config
    fi
}

setup_dev()
{
    setup_mirrors
    setup_ssh_config
    test_create_dirs dev
    pushd dev > /dev/null || die "Error switching to dev"
    test_git_or_mirror_clone core git://gerrit.libreoffice.org/core
    pushd core > /dev/null || die "Error swithing to dev/core"
    git config remote.origin.pushurl ssh://lode/core || die "Error setup the pushurl for core"
    if [ ! -f autogen.input ] ; then
        if [ -f "${BASE_DIR?}/autogen.input.base" ] ; then
            cat "${BASE_DIR?}/autogen.input.base" > autogen.input || die "Error populating autogen.input from autogen.input.base"
        fi
        echo "--enable-debug" >> autogen.input || die "Error adding --enable-debug to autogen.input"
    fi
    popd > /dev/null || die "Error popping core"
    popd > /dev/null || die "Error poping dev"
}

install_build_dep()
{
    echo "***********" >&1
    echo "WARNING**** Install Build Dep is not supported yet on this platform ****" 2>&1
    echo "***********" >&1
}

display_prereq()
{
    os_prereq
    os_flavor_prereq

cat <<EOF

Done.

EOF
}

final_notes()
{
    os_notes
    os_flavor_notes
    cat <<EOF

    add in your profile.
    export LODE_HOME=$(pwd)
Done.

EOF
}
