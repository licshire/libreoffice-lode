

os_prereq()
{
cat <<EOF

For MacOSX you need to install XCode ( https://developer.apple.com/xcode/ ) and run it once to accept the license.
You also need to install a JDK. ( http://www.oracle.com/technetwork/java/javase/downloads/index.html )

EOF
}

determine_os_flavor()
{
    kernel=$(uname -r)

    case "$kernel" in
	13.*)
	    OS_FLAVOR=10.9
	    ;;
	*)
	    die "Unknown Darwin kernel version ${kernel}"
	    ;;
    esac
    export PATH=${BASE_DIR}/opt/bin:$PATH
}