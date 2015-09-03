# -*- tab-width : 4; indent-tabs-mode : nil -*-
#
#    Copyright (C) 2014 Norbert Thiebaud
#    License: GPLv3
#


get_remote_file()
{
    local url="$1"
    local f="$2"

    if [ -n "$f" ] ; then
	curl -O ${url?} -o ${f?} || die "Error download ${module?} source package"
    else
	curl -O ${url?} || die "Error download ${module?} source package"
    fi
}

os_prereq()
{
cat <<EOF

For MacOSX you need to install XCode ( https://developer.apple.com/xcode/ ) and run it once to accept the license.
You also need to install a Java, see  http://support.apple.com/kb/dl1572
http://support.apple.com/downloads/DL1572/en_US/JavaForOSX2014-001.dmg
EOF
}

determine_os_flavor()
{
    kernel=$(uname -r)

    case "$kernel" in
	13.*)
	    OS_FLAVOR=10.9
	    ;;
	14.*)
	    OS_FLAVOR=10.10
	    ;;
	*)
	    die "Unknown Darwin kernel version ${kernel}"
	    ;;
    esac
    if [ -n "$(type -p port 2> /dev/null)" ] ; then
        die "lode does not support macport. more exactly macport can interfere with lode setup and LibreOffice build. please remove it from your PATH when doing lode work"
    fi
    export PATH=${BASE_DIR}/opt/bin:$PATH
}
