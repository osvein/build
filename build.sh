#!/bin/sh

set -o errexit -o pipefail -o noclobber
IFS='
'
TMPDIR="${TMPDIR-/tmp}"
tmpdir="$TMPDIR/$0.$$"
mkdir "$tmpdir"
trap "rm -r $tmpdir" EXIT
semaphore="$tmpdir/semaphore"
mkfifo "$semaphore"
printf '\n\n\n\n\n\n\n\n' >>"$semaphore" &
exec 3<"$semaphore" 4>>"$semaphore"

sem_wait() {
    dd of=/dev/null bs=1 count=1 <&3 2>>/dev/null
}

sem_post() {
    echo >&4
}

event_wait() {
    mkfifo "$1" 2>>/dev/null || true
    <"$1"
}

event_set() {
    mkfifo "$1" 2>>/dev/null || true
    exec sleep 32767 <"$1" & # sleep to prevent sh from reaping
    : >"$1.tmp"
    mv -f "$1.tmp" "$1" >>"$1"
    kill $! # kill in case it blocks on opening fifo
}

event_clear() {
    rm "$1" 2>>/dev/null || true
}

runcmds() {
    waitlist=
    while read line; do
        cmd=${line%% *}
        arg=${line#* }
        case "$cmd" in
        "dep")
            waitlist="$waitlist
$arg"
            ;;
        "wait")
            sem_post
            for target in $waitlist; do
                build "$target"
            done
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

build() {
    target="${1-Buildfile}"
    fifo="$tmpdir/$target.stdin"
    mkfifo "$fifo" 2>>/dev/null || return 0
    sem_wait
    (
        ./Buildfile "$@" <"$fifo" | runcmds >>"$fifo"
        event_set "$tmpdir/$target.event"
        sem_post
    ) &
}

build
wait $!
