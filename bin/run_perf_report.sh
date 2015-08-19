#!/bin/bash

[ $debug ] && set -x

die()
{
    echo "Error:" "$@" >&2
    exit -1;
}

add_value()
{
    local suite="$1"
    local name="$2"
    local total="$3"

    pushd "${TARGETDIR?}/data" > /dev/null || die "cannot cd to $TARGETDIR/data"
    if [ ! -d "${suite?}" ] ; then
	mkdir "${suite?}"
    fi
    echo "add cpu:$total to ${suite}/${name}.data"
    echo "$N $SHA ${total}" >> ${suite}/${name}.data
    cat ${suite}/${name}.data | sort -u -k 2 | sort -n > ${suite}/${name}.data.new && mv ${suite}/${name}.data.new ${suite}/${name}.data


    popd > /dev/null
}

do_callgrind_out()
{
    local f="$1"
    local suite
    local total
    local title

    title=$(grep "^desc: Trigger: Client Request: " $f | sed -e 's/desc: Trigger: Client Request: //' | sed -e 's/[ \-]/_/g')
    total=$(grep "^totals:" $f | sed -e 's/^totals: //')
    suite=$(basename $(dirname $f) | sed -e 's/\.test\.core//')
#    echo "f:$f b:$suite t:|$title| c:$total"
    if [ "$title" != "" ] ; then
	add_value "$suite" "$title" "$total"
    fi
}

find_callgrind_out()
{
    local f

    pushd ${BUILDDIR?}/CppunitTest > /dev/null || die "can cd to $BUILDDIR/CppunitTest"
    for f in $(find . -name "callgrind.out.*") ; do
	do_callgrind_out "$f"
    done
    popd > /dev/null
}


SOURCEDIR='.'
BUILDDIR='./workdir'
TARGETDIR="$HOME/perf_www"
N="$(date +%s)"

while [ "${1}" != "" ]; do
    parm=${1%%=*}
    arg=${1#*=}
    has_arg=
    if [ "${1}" != "${parm?}" ] ; then
        has_arg=1
    else
        arg=""
    fi

    case "${parm}" in
        --builddir)
            BUILDDIR="$arg"
            ;;
        --sourcedir)
            SOURCEDIR="$arg"
            ;;
        --targetdir)
            TARGETDIR="$arg"
            ;;
	--time)
	    N="$arg"
	    ;;
        -*)
            die "Invalid option $1"
            ;;
        *)
            die "Invalid argument $1"
            ;;
    esac
    shift
done

SHA=$(git rev-parse HEAD)

find_callgrind_out

