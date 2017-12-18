#!/usr/bin/env bash
# -*- tab-width : 4; indent-tabs-mode : nil -*-
#
# This file is part of the LibreOffice project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

[ "$DEBUG" ] && set -xv

#
# Functions
#

#
# Display an error message and exit
#
die()
{
    echo "Error:" "$@" >&2
    exit -1;
}

lcov_cleanup()
{
    lcov --zerocounters --directory "$(pwd)"
}

source_build()
{
    ./autogen.sh --disable-gtk3 --enable-debug --enable-python=internal --disable-online-update --without-system-libs --with-system-nss --without-system-headers --disable-ccache --disable-coinmp --disable-firebird-sdbc \
    || die "autogen.sh failed."

    make clean
    gb_GCOV=YES make build-nocheck || die "make build-nocheck failed."

    if [ ! -d workdir/lcov ] ; then
        mkdir -p workdir/lcov || die "creating workdir/lcov"
    fi
}

lcov_tracefile_baseline()
{
    lcov --rc geninfo_auto_base=1 --capture --initial --directory "$(pwd)" --output-file "$(pwd)/workdir/lcov/lcov_base.info" --test-name "jenkins" \
    || die "Tracefile $(pwd)/workdir/lcov/lcov_base.info generation failed."
}

lcov_tracefile_tests()
{
    lcov --rc geninfo_auto_base=1 --capture --directory "$(pwd)" --output-file "$(pwd)/workdir/lcov/lcov_test.info" --test-name "jenkins" \
    || die "Tracefile $(pwd)/workdir/lcov_test.info generation failed."
}

lcov_tracefile_join()
{
    lcov --rc geninfo_auto_base=1 --add-tracefile "$(pwd)/workdir/lcov/lcov_base.info" \
    --add-tracefile "$(pwd)/workdir/lcov/lcov_test.info" --output-file "$(pwd)/workdir/lcov/lcov_total.info" --test-name "jenkins" \
    || die "Tracefile generation $(pwd)/workdir/lcov/lcov_total.info failed."
}

lcov_tracefile_cleanup()
{
    lcov --rc geninfo_auto_base=1 --remove "$(pwd)/workdir/lcov/lcov_total.info" \
    "/usr/include/*" "/usr/lib/*" "$(pwd)/*/UnpackedTarball/*" "$(pwd)/workdir/*" \
    "$(pwd)/instdir/*" "$(pwd)/external/*" \
    -o "$(pwd)/workdir/lcov/lcov_filtered.info" --test-name "jenkins" \
    || die "tracefile generation $(pwd)/workdir/lcov/lcov_filtered.info failed."
}

lcov_mkhtml()
{
    rm -fr /home/tdf/www_new
    mkdir "/home/tdf/www_new" || die "Failed to create target directory /home/tdf/www_new"

    genhtml --rc geninfo_auto_base=1 --prefix "$(pwd)" --ignore-errors source "$(pwd)/workdir/lcov/lcov_filtered.info" \
    --legend --title "jenkins core coverage" --rc genhtml_desc_html=1 \
    --output-directory="/home/tdf/www_new" --description-file "$(pwd)/workdir/lcov/descfile.desc" \
    || die "ERROR: Generation of html files in /home/tdf/www_new failed."
}

lcov_get_commit()
{
    COMMIT_SHA1=$(git log --date=iso | head -3 | awk '/^commit/ {print $2}')
    COMMIT_DATE=$(git log --date=iso | head -3 | awk '/^Date/ {print $2}')
    COMMIT_TIME=$(git log --date=iso | head -3 | awk '/^Date/ {print $3}')
}

lcov_mk_desc()
{
    echo "TN: jenkins" > "$(pwd)/workdir/lcov/descfile.desc"
    echo "TD: Commit SHA1: ${COMMIT_SHA1?} <br>" >> "$(pwd)/workdir/lcov/descfile.desc"
    echo "TD: Commit DATE: ${COMMIT_DATE?} ${COMMIT_TIME?} <br>" >> "$(pwd)/workdir/lcov/descfile.desc"
    echo "TD: Source Code Directory: $(pwd) <br>" >> "$(pwd)/workdir/lcov/descfile.desc"
}

#
# Main
#

DESC_FILE=descfile.desc

LDFLAGS+='-fprofile-arcs'
CFLAGS+='-fprofile-arcs -ftest-coverage'
CXXFLAGS+='-fprofile-arcs -ftest-coverage'
CPPFLAGS+='-fprofile-arcs -ftest-coverage'

export LDFLAGS
export CFLAGS
export CXXFLAGS
export CPPFLAGS

source_build

lcov_cleanup
lcov_get_commit
lcov_tracefile_baseline
lcov_mk_desc

gb_GCOV=YES make -k check

lcov_tracefile_tests
lcov_tracefile_join
lcov_tracefile_cleanup
lcov_mkhtml
rm -rf /home/tdf/www_old
chmod -R 755 /home/tdf/www_new || die "Failed to set permissions"
if [ -d /home/tdf/www ] ; then
    mv /home/tdf/www /home/tdf/www_old
fi
mv /home/tdf/www_new /home/tdf/www
cat <<EOF > /home/tdf/www/robots.txt
User-agent: *
Disallow: /
EOF
