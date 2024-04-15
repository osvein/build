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
    semaphore="$tmpdir/semaphore"
    mkfifo "$semaphore"
    printf '\n\n\n\n\n\n\n\n' >>"$semaphore" &
    exec 3<"$semaphore" 4>>"$semaphore"
fi

sem_wait() {
    echo sem_wait >&2
    dd of=/dev/null bs=1 count=1 <&3 2>>/dev/null
}

sem_post() {
    echo sem_post >&2
    echo >&4
}

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
            "$self" "$arg" 3<&3 4>&4 &
            waitlist="$waitlist
$arg"
            ;;
        "wait")
            sem_post
            for target in $waitlist; do
                event_wait "$tmpdir/$target.event"
            done
            sem_wait
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
sem_wait
./Buildfile "$@" <"$fifo" | runcmds >>"$fifo"
event_set "$tmpdir/$target.event"
sem_post
wait
