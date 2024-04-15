dep() {
    for prereq in "$@"; do
        echo dep "$prereq"
    done
}

wait() {
    echo wait
    read ignore
}

# convert Makefile-like output from makedepend / cc -M to build commands
# usage: ./make2build.sh target_name <depend_file
make2build() {
    sed '
/^\t/d
s/^[^:]*'"$1"'[^:]*:[[:space:]]*//
t a
d
:a
s/\\$//
t b
b c
:b
N
b a
:c
s/[[:space:]]*$//
s/[[:space:]]\{1,\}/\ndep /g
s/^/dep /
'
}
