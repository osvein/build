#!/bin/sh

set -o errexit -o pipefail -o noclobber
IFS='
'
TMPDIR="${TMPDIR-/tmp}"
self="$0"
tmpdir="$TMPDIR/$self.${BUILD_PID:-$$}"
if [ ! "$BUILD_PID" ]; then
    export BUILD_PID=$$
    mkdir "$tmpdir"
    trap "rm -r $tmpdir" EXIT
fi

event_wait() {
    mkfifo "$1" 2>>/dev/null || true
    <"$1"
}

event_set() {
    : >"$tmpdir/$$"
    event_wait "$1" & mv -f "$tmpdir/$$" "$1" >>"$1"
}

event_clear() {
    rm "$1" 2>>/dev/null || true
}

runcmds() {
    waitlist=
    while read line; do
        #echo "command: $line" >&2
        cmd=${line%% *}
        arg=${line#* }
        case "$cmd" in
        "dep")
            "$self" "$arg" &
            waitlist="$waitlist
$arg"
            ;;
        "wait")
            for target in $waitlist; do
                event_wait "$tmpdir/$target.event"
            done
            echo
            ;;
        *)
            echo "$1: invalid command: $cmd" >&2
            ;;
        esac
    done
}

echo "./Buildfile $*" >&2
target="${1-Buildfile}"
fifo="$tmpdir/$target.stdin"
mkfifo "$fifo" 2>>/dev/null || exit 0
./Buildfile "$@" <"$fifo" | runcmds >>"$fifo"
event_set "$tmpdir/$target.event"
wait
