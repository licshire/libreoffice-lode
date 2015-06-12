

.PHONY: all

all:
	TMP="`pwd`/tempdir" TMPDIR="`pwd`/tempdir" make && echo '#######SUCCESS#######';

check:
	TMP="`pwd`/tempdir" TMPDIR="`pwd`/tempdir" make check && echo '#######SUCCESS#######';
