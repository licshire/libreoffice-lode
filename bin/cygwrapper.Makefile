

.PHONY: all

all:
	TMP="`pwd`/tempdir" TMPDIR="`pwd`/tempdir" make && echo '#######SUCCESS#######';
