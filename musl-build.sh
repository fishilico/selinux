#!/bin/sh
exec make DESTDIR=$(pwd)/DESTDIR CC="musl-gcc -I$(pwd)/musl-headers -L$(pwd)/musl-headers/lib -lfts -DGLOB_TILDE=0 -DGLOB_BRACE=0" install -k
