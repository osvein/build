#!/bin/sh
# source common.sh first

AR="${AR:-ar}"
ARFLAGS="${ARFLAGS:--rv}"
YACC="${YACC:-yacc}"
LEX="${LEX:-lex}"
CC="${CC:-c99}"
CFLAGS="${CFLAGS:--O1}"
FC="${FC=fort77}"
FFLAGS="${FFLAGS:--O1}"

exe() {
    name="$1"
    shift
    dep "$@"
    wait
    "$CC" $CFLAGS $LDFLAGS -o "$name" "$@"
}

c2o() {
    dep "$1.c"
    wait
    "$CC" $CFLAGS -c "$1.c" -MMD
    make2build "$1" <"$1.d"
    rm "$1.d"
    wait
}
