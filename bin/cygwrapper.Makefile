

.PHONY: all check screenshot

all:
	TMP="`pwd`/tempdir" TMPDIR="`pwd`/tempdir" make && echo '#######SUCCESS#######';

check:
	TMP="`pwd`/tempdir" TMPDIR="`pwd`/tempdir" make check && echo '#######SUCCESS#######';

screenshot:
	TMP="`pwd`/tempdir" TMPDIR="`pwd`/tempdir" make screenshot && echo '#######SUCCESS#######';
