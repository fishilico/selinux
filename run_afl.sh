#!/bin/bash
# Run american fuzzy lop on a SELinux program

# Force every commands to succeed
set -e

# Force the current directory
cd "$(dirname -- "$0")"

# Directory where SELinux tools & libraries are compiled
DESTDIR='./DESTDIR'
FULL_DESTDIR="$(pwd)/$DESTDIR"

usage() {
    cat << EOF
Usage: $0 PROG
Run afl-fuzz on PROG

PROG:
  * build               special target to rebuild all the project
  * build-quick         special target to rebuild the project without cleaning
  * secilc              compile a CIL policy
  * secilc-test         use secilc/test/ testcases
  * checkmodule         compile a .te module into a .mod
  * semodule_package    compile a .te module into a .pp
  * pp                  translate a .pp module to a CIL policy
EOF
}

# No arguments or too many => usage
if [ $# -eq 0 ] ; then
    usage
    exit
fi

run_make() {
    echo "Running: make CC=afl-gcc DEBUG=1 PYTHON=python3 DESTDIR='$FULL_DESTDIR' $*"
    make CC=afl-gcc DEBUG=1 PYTHON=python3 DESTDIR="$FULL_DESTDIR" "$@"
}

# Compile and install programs in DESTDIR
if [ "$1" = build ] || ! [ -x "$DESTDIR/usr/bin/semodule_package" ] ; then
    run_make clean distclean
    if [ -e "$DESTDIR" ] ; then
        rm -f "$DESTDIR/usr/bin/newrole"
        rm -r "$DESTDIR"
    fi
    run_make install "-j$(nproc)"
    run_make install-pywrap "-j$(nproc)"
    run_make install-rubywrap "-j$(nproc)"
elif [ "$1" = build-quick ] ; then
    run_make install "-j$(nproc)"
    run_make install-pywrap "-j$(nproc)"
    run_make install-rubywrap "-j$(nproc)"
fi

# Set-up environment
export LD_LIBRARY_PATH="$FULL_DESTDIR/usr/lib:$FULL_DESTDIR/lib"

# Compile intermediary output files
compile_basic_mod() {
    mkdir -p 'afl-in/mod'
    "$DESTDIR/usr/bin/checkmodule" -m -o 'afl-in/mod/basic.mod' 'afl-in/te/basic.te'
}
compile_basic_pp() {
    compile_basic_mod
    mkdir -p 'afl-in/pp'
    "$DESTDIR/usr/bin/semodule_package" --outfile 'afl-in/pp/basic.pp' \
        --module 'afl-in/mod/basic.mod' --fc 'afl-in/fc/basic.fc'
}

# Create a temporary directory for various outputs
TEMP_OUTDIR="$(mktemp -d "${TMPDIR:-/tmp}/selinux_run_afl_XXXXXX")"
trap 'rm -rf "$TEMP_OUTDIR"' EXIT HUP INT QUIT TERM

case "$1" in
    build|build-quick)
        # Quit here if only a build has been requested
        exit
        ;;
    secilc)
        PROG="$DESTDIR/usr/bin/secilc"
        PROGOPTS=(-o /dev/null -f /dev/null)
        INDIR='afl-in/cil'
        INFILE='basic.cil'
        ;;
    secilc-test)
        PROG="$DESTDIR/usr/bin/secilc"
        PROGOPTS=(-o /dev/null -f /dev/null)
        INDIR='secilc/test'
        INFILE='minimum.cil'
        TITLE='secilc with included test cases'
        ;;
    checkmodule)
        PROG="$DESTDIR/usr/bin/checkmodule"
        PROGOPTS=(-m -o "$TEMP_OUTDIR/basic.mod")
        INDIR='afl-in/te'
        INFILE='basic.te'
        ;;
    semodule_package)
        PROG="$DESTDIR/usr/bin/semodule_package"
        PROGOPTS=(--outfile "/dev/null" --module)
        INDIR='afl-in/mod'
        INFILE='basic.mod'
        compile_basic_mod
        ;;
    pp)
        PROG="$DESTDIR/usr/libexec/selinux/hll/pp"
        PROGOPTS=()
        INDIR='afl-in/pp'
        INFILE='basic.pp'
        compile_basic_pp
        ;;
    *)
        echo >&2 "Error: unknown program $1"
        usage >&2
        exit 1
        ;;
esac
TITLE="${TITLE:-${PROG##*/}}"

# Sanity check: verify that the program works
"$PROG" "${PROGOPTS[@]}" "$INDIR/$INFILE" > /dev/null

# Create an output directory depending on the date
#OUTDIR="afl-out/$1_$(date +'%Y-%m-%d')"
# Create an output directory which will continuously gather new test cases
OUTDIR="afl-out/$1"
mkdir -p "$OUTDIR"

# Continue if the directory already exists
if [ -e "$OUTDIR/fuzzer_stats" ] ; then
    echo "Continuing previous afl-fuzz run from $OUTDIR"
    INDIR='-'
fi

# Run AFL
afl-fuzz -T "$TITLE" -i "$INDIR" -o "$OUTDIR" "$PROG" "${PROGOPTS[@]}" @@
