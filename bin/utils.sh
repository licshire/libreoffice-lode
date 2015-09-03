# -*- tab-width : 4; indent-tabs-mode : nil -*-
#
#    Copyright (C) 2014 Norbert Thiebaud
#    License: GPLv3
#

#
# Display an error message and exit
#
die()
{
    echo  "$@"
    exit 1;
}

setup_git_hooks()
{
    pushd "${BASE_DIR?}/.git-hooks" > /dev/null || die "Error cd-ing to .git-hooks"
    hooks=$(ls -1);
    popd > /dev/null
    pushd "${BASE_DIR?}/.git/hooks" > /dev/null || die "Error cd-ing to .git/hooks"

    for hook in $hooks ; do
        if [ ! -e "${hook?}" -o -L "${hook?}" ] ; then
            rm -f "${hook?}"
            ln -sf "../../.git-hooks/${hook?}" "${hook?}"
        fi
    done
    popd > /dev/null
}

#
# Test if a directory exist, if not create it
#
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

#
# Test if a list of directories exist
# create the ones that do not
#
test_create_dirs()
{
    local d=

    for d in "$@" ; do
        test_create_dir "${d}"
    done
}


#
# fetch a file via http
#
get_remote_file()
{
    local url="$1"
    local f="$2"
    which wget > /dev/null 2> /dev/null
    if [ "$?" = "0" ] ; then
        if [ -n "$f" ] ; then
            wget -O ${f?} ${url?} || die "Error download ${module?} source package"
        else
            wget ${url?} || die "Error download ${module?} source package"
        fi
    else
        if [ -n "$f" ] ; then
            curl -o ${f?} ${url?} || die "Error download ${module?} source package"
        else
            curl -O ${url?} || die "Error download ${module?} source package"
        fi
    fi
}

#
# test if a git repo exist, if not clone it
#
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
                pushd $(pwd)/${g} > /dev/null
                git config --add remote.origin.fetch "+refs/notes/*:refs/notes/*"
                popd > /dev/null
            else
                echo "Error Cloning $(pwd)/${g}" 1>&2
                rm -fr "${g}"
                exit 1
            fi
        fi
    fi
}

#
# test if a bare git repo mirror exist
# if not clone it
#
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

#
# test if a git repo exist
#  if not clone it using --reference to a local mirror
#
test_git_or_mirror_clone()
{
    # test if a git repo exist, if not clone it, using a reference mirror if available
    # you need to have the current working dir be where you want to clone
    local g="$1"
    local remote="$2"
    local r="$3"

    if [ -n "${r}" -a -n "${remote}" ] ; then
        if [ -d "${r?}" ] ; then
            if [ -d "${r?}/.git" ] ; then
                echo "git repo '$(pwd)/${r?}' exist" 1>&2
            else
                echo "Error $(pwd)/${r?} is a directory but not a git repo" 1>&2
                exit 1
            fi
        elif [ -e "${r}" ] ; then
            echo "Error $(pwd)/${r?} is a directory but not a git repo" 1>&2
            exit 1
        else
            if [ -d "${BASE_DIR?}/mirrors/${g?}.git" ] ; then
                git clone --reference "${BASE_DIR?}/mirrors/${g?}.git" "${remote?}" "${r?}"
            else
                git clone "${remote?}" "${r?}"
            fi
            if [ $? = "0" ] ; then
                echo "Cloned $(pwd)/${r?}" 1>&2
                pushd $(pwd)/${r} > /dev/null
                git config --add remote.origin.fetch "+refs/notes/*:refs/notes/*"
                popd > /dev/null
            else
                echo "Error Cloning $(pwd)/${r?}" 1>&2
                rm -fr "${r}"
                exit 1
            fi
        fi
    fi
}


#
# download and untar a package
#
fetch_and_unpack_package()
{
    local module="$1"
    local version="$2"
    local base_url="$3"
    local fn="$4"

    if [ -z "${module}" -o -z "${version}" -o -z "${base_url}" -o -z "${fn}" ] ; then
        die "Mssing/Invalid parameter to install_generic_conf_make_install()"
    fi
    pushd "${BASE_DIR?}/packages" > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
    rm -fr "${BASE_DIR?}/packages/${module?}-${version?}"
    rm -f "${BASE_DIR?}/packages/${fn?}"
    get_remote_file "${base_url?}/${fn?}"
    tar -xf ${fn?} || die "Error untaring ${module?} source"
    popd > /dev/null
}
#
# test if a module is installed
# if not do the standard configure/make/make install dance
#
install_generic_conf_make_install()
{
    local module="$1"
    local version="$2"
    local base_url="$3"
    local fn="$4"

    if [ -z "${module}" -o -z "${version}" -o -z "${base_url}" -o -z "${fn}" ] ; then
        die "Mssing/Invalid parameter to install_generic_conf_make_install()"
    fi
    if [ ! -x "${BASE_DIR?}/opt/bin/${module?}" -o ! -d "${BASE_DIR?}/packages/${module?}-${version?}" -o -f "${BASE_DIR?}/packages/${module?}-${version?}/.lode_building" ]; then
        echo "installing ${module?}..." 1>&2
        fetch_and_unpack_package "${module?}" "${version?}" "${base_url?}" "$fn"
        pushd "${BASE_DIR?}/packages/${module?}-${version?}" > /dev/null || die "Error cd-ing to ${module} source tree"
        touch .lode_building
        ./configure --prefix="${BASE_DIR?}/opt" || die "Error configuring ${module?}"
        make || die "error building ${module?}"
        make install || die "error installing ${module?}"
        rm .lode_building
        popd > /dev/null
        echo "${module?} Installed" 1>&2
    else
        echo "${module?} already installed" 1>&2
    fi
}

install_private_cmake()
{
    local module="cmake"
    local version="$1"
    local base_url="$2"
    local fn="$3"

    if [ -z "${version}" -o -z "${base_url}" -o -z "${fn}" ] ; then
        die "Mssing/Invalid parameter to install_private_cmake()"
    fi
    if [ ! -x "${BASE_DIR?}/opt/private_lode/bin/${module?}" -o -f "${BASE_DIR?}/packages/${module}-${version}/.lode_building" -o ! -d "${BASE_DIR?}/packages/${module}-${version?}" ]; then
        echo "installing ${module?}..." 1>&2
        fetch_and_unpack_package "${module?}" "${version?}" "${base_url?}" "$fn"
        pushd "${BASE_DIR?}/packages/${module?}-${version?}" > /dev/null || die "cd-ing to cmake source directory"
        touch .lode_building
        ./bootstrap --prefix="${BASE_DIR?}/opt/lode_private" --parallel=$(sysctl -n hw.ncpu) || die "bootstraping cmake"
        make -j $(sysctl -n hw.ncpu) || die "Error making ${module}"
        make install || die "Errror installing ${module}"
        rm .lode_building
        popd > /dev/null
    else
        echo "${module?} already installed" 1>&2
    fi
}

install_doxygen()
{
    local module="doxygen"
    local version="$1"
    local base_url="$2"
    local fn="$3"

    if [ -z "${version}" -o -z "${base_url}" -o -z "${fn}" ] ; then
        die "Mssing/Invalid parameter to install_private_cmake()"
    fi
    if [ ! -x "${BASE_DIR?}/opt/bin/${module?}" -o -f "${BASE_DIR?}/packages/${module}-${version}/.lode_building" -o ! -d "${BASE_DIR?}/packages/${module}-${version?}" ]; then
        echo "installing ${module?}..." 1>&2
        fetch_and_unpack_package "${module?}" "${version?}" "${base_url?}" "$fn"
        pushd "${BASE_DIR?}/packages/${module?}-${version?}" > /dev/null || die "cd-ing to cmake source directory"
        touch .lode_building
        "${BASE_DIR?}/opt/lode_private/bin/cmake" -G "Unix Makefiles" -Denglish_only=YES -DCMAKE_INSTALL_PREFIX="${BASE_DIR?}/opt" || die "Error preparing make for doxygen"
        make -j $(sysctl -n hw.ncpu) || die "error making doxygen"
        make install || die "Errror installing ${module}"
        rm .lode_building
        popd > /dev/null
    else
        echo "${module?} already installed" 1>&2
    fi

}

install_ant()
{
    local ant_version=apache-ant-1.9.4

    if [ ! -x "${BASE_DIR?}/opt/ant/bin/ant" ] ; then
        if [ -L "${BASE_DIR?}/opt/bin/ant" ] ; then
            unlink "${BASE_DIR?}/opt/bin/ant"
        fi
        pushd "${BASE_DIR?}/packages" > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
        rm -fr "${BASE_DIR?}/packages/${ant_version?}"
        rm -f "${BASE_DIR?}/packages/${ant_version?}-bin.zip"
        get_remote_file "http://archive.apache.org/dist/ant/binaries/${ant_version?}-bin.zip"
        unzip ${ant_version?}-bin.zip || die "Error unziping ant"
        rm -fr "${BASE_DIR?}/opt/ant"
        cp -r "${BASE_DIR?}/packages/${ant_version?}" "${BASE_DIR?}/opt/ant" || die "Delivering and to ${BASE_DIR?}/opt"
        popd > /dev/null || die "Error switching to ${BASE_DIR?}/packages"
        echo "ant Installed" 1>&2
    else
        echo "ant already installed" 1>&2
    fi

}

install_junit()
{
    if [ -f "${BASE_DIR?}/opt/share/java/junit.jar" ] ; then
        echo "junit Already Installed" 1>&2
    else
        test_create_dirs "${BASE_DIR?}/opt/share" "${BASE_DIR?}/opt/share/java"
        which wget > /dev/null 2> /dev/null
        if [ "$?" = "0" ] ; then
            wget -O "${BASE_DIR?}/opt/share/java/junit.jar" http://downloads.sourceforge.net/project/junit/junit/4.10/junit-4.10.jar || die "Error wgetting junit"
        else
            curl -o "${BASE_DIR?}/opt/share/java/junit.jar" -O#L "https://github.com/downloads/junit-team/junit/junit-4.11.jar" || die "Error downloading junit"
        fi
        echo "junit Installed" 1>&2
    fi
}

determine_os_flavor()
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
    if [ "$DO_FORCE" = 1 ] ; then
        rm -fr "${BASE_DIR?}/opt"
    fi
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
    if [ -d ~/.ssh ] ; then
        cat >> ~/.ssh/config <<EOF

Host lode
Hostname gerrit.libreoffice.org
Port 29418

EOF
    fi
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

gc_repos()
{
    base="$1"
    pushd "$base" || die "Error switching to $base"
    for repo in $(ls -1) ; do
        if [ -d ${repo}/.git ] ; then
            pushd ${repo}
            if [ -f ${repo}/Repository.mk ] ; then
                echo "${BASE_DIR?}/mirrors/core.git/object" > .git/objects/info/alternate
            fi
            git gc
            popd > /dev/null
        fi
    done
    popd > /dev/null
}

refresh_repos()
{
    pushd "${BASE_DIR?}/mirrors/core.git" > /dev/null || die "Error switching to mirror"
    git remote update
    popd > /dev/null
    gc_repos "${BASE_DIR?}/dev"
}

create_new_work_clone()
{
repo="$1"

    if [ -e dev/${repo} ] ; then
        die "dev/${repo} already exist"
    else
        pushd dev > /dev/null || die "Error switching to dev"
        test_git_or_mirror_clone "core" git://gerrit.libreoffice.org/core "${repo}"
        pushd "${repo}" > /dev/null || die "Error swithing to dev/${repo}"
        git config remote.origin.pushurl ssh://lode/core || die "Error setup the pushurl for ${repo}"
    fi
    popd > /dev/null || die "Error popping ${core}"
    popd > /dev/null || die "Error poping dev"
}

setup_dev()
{
    setup_mirrors
    setup_ssh_config
    test_create_dirs dev
    pushd dev > /dev/null || die "Error switching to dev"
    test_git_or_mirror_clone core git://gerrit.libreoffice.org/core core
    pushd core > /dev/null || die "Error swithing to dev/core"
    git config remote.origin.pushurl ssh://lode/core || die "Error setup the pushurl for core"
    if [ ! -f autogen.input ] ; then
        echo "--enable-debug" > autogen.input || die "Error adding --enable-debug to autogen.input"
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

if [ -z "${LODE_HOME}" ] ; then
    cat <<EOF

    add in your profile.
    export LODE_HOME=$(pwd)
EOF
fi
echo ""
echo "   Done."
}
