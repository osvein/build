usage:

- copy build.sh and any utility scripts into your project
- write a Buildfile (see test/ for examples)
- run ./build.sh in the project directory

protocol:

build.sh is the basic implementation of the build server. The build server
executes a Buildfile. The Buildfile can be written in any language, as long as
it can be executed (e.g. using a shebang). The Buildfile sends commands to the
build server using its standard output, and receives responses on the standard
input. The following commands are supported:

- dep file - cause the current target to be rebuilt when file had been modified
- wait - build all dependencies of the current target, responds with a single
  newline character when finished

Buildfile is executed with the name of a target to be built passed as argument.
Initially, if the build server was invoked with no targets specified, the
Buildfile is executed without arguments.

roadmap:

- implement a build server in C with incremental building
