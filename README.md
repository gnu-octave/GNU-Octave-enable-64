# GNU Octave enable-64

This project targets compiling [GNU Octave](http://www.gnu.org/software/octave/)
using 64-bit indices on **Linux systems**.

## For quick starters

If all GNU Octave
[build dependencies](https://www.gnu.org/software/octave/doc/interpreter/Build-Dependencies.html)
are installed, just type the following commands:

```
git clone https://github.com/siko1056/GNU-Octave-enable-64.git
cd GNU-Octave-enable-64
make
./build/octave/run-octave
```

## More details

In particular, a Makefile is provided containing all necessary information to
compile

- [OpenBLAS](http://www.openblas.net) (0.2.18),
- [SuiteSparse](http://www.suitesparse.com) (4.5.2),
- [QRUPDATE](http://sourceforge.net/projects/qrupdate) (1.1.2),
- [ARPACK](https://github.com/opencollab/arpack-ng) (3.3.0), and
- [GNU Octave](http://www.gnu.org/software/octave/) (development version)

using 64-bit indices.  To get a quick overview about the library dependencies,
the following figure visualizes them top-down:  "The above requires all
libraries below".

```
+-------------------------------------------------------+
|                     GNU Octave                        |
+-------------+-------------+-------------+-------------+
|             | SuiteSparse |  QRUPDATE   |   ARPACK    |
|             +-------------+-------------+-------------+
| OpenBLAS                                              |
+-------------------------------------------------------+
```

> Notice: It is assumed, that the user of this Makefile is already capable of
> building the "usual" Octave development version!

Means, that all other
[build dependencies](https://www.gnu.org/software/octave/doc/interpreter/Build-Dependencies.html)
(e.g. libtool, gfortran, ...) are properly installed on the system and, even
better, building the "usual" Octave development version runs flawless. Building
this project requires approximately **4 GB** disc space and **2 hours**,
depending on your system.

Using this Makefile is especially of interest, if one pursues the following
goals:

1. No root privileges required.
2. No collision with system libraries.

Both abovementioned goals are archived by building and deploying the required
libraries in an arbitrary directory **ROOT_DIR**.  This directory can be
set by calling the Makefile like:

```
make ROOT_DIR=$HOME/some/path
```

The internal directory structure relative to *ROOT_DIR* is:

```
ROOT_DIR
|-- build          # local build directory for each library
|    |-- arpack
|    |-- octave
|    +--  ...
|-- libs           # local replacement for system wide library
|    |-- include   # deployment, like  /usr  or  /usr/local
|    +-- lib
+-- source-cache   # location for downloaded library sources
     |-- arpack-$(VER).tar.gz
     +--  ...
```

All required libraries are built according to this pattern:

1. Download the source code
2. Extract the source code to directory *ROOT_DIR/build*
3. Configure and build the library (sometimes with ugly hacks)
  1. Ensure usage of 64-bit indices.
  2. Ensure the suffix "_Octave64" in the library's
     [SONAME](https://en.wikipedia.org/wiki/Soname).
4. Deploy the library in *ROOT_DIR/libs/lib* (sometimes with ugly hacks)

To guarantee the usage of the self compiled libraries, even in presence of
a system wide installed substitute, the library's
[SONAME](https://en.wikipedia.org/wiki/Soname) is changed to enforce a hard
error if the "wrong" library is taken.  Therefore it would even be possible
to deploy the self compiled libraries system wide.  The SONAME can be set by
calling the Makefile like:

```
make SONAME_SUFFIX=
make SONAME_SUFFIX=Octave64
```

The first call leaves the library names unchanged, while the second call adds
the suffix "_Octave64" to each library, which is the default behavior.  For
more information on shared libraries in common Linux distributions, see the
subsection below.

For more information on the topic of building GNU Octave using large indices,
check the
[GNU Octave manual](https://www.gnu.org/software/octave/doc/interpreter/Compiling-Octave-with-64_002dbit-Indexing.html)
or the
[GNU Octave wiki](http://wiki.octave.org/Enable_large_arrays:_Build_octave_such_that_it_can_use_arrays_larger_than_2Gb.).


## Similar works

This project is greatly inspired by a
[blog post by Richard Calaba](http://calaba.tumblr.com/post/107087607479/octave-64),
who created one year ahead a
[GitHub](https://github.com/calaba/octave-3.8.2-enable-64-ubuntu-14.04)
repository for GNU Octave 3.8.

For Windows, there is a cross-compiling solution, called
[MXE-Octave](http://wiki.octave.org/MXE).  It compiles all dependencies from
scratch, thus requires much more disc space and time than this approach.


## Shared libraries and debugging techniques

As all of this project deals with the correct treatment of shared libraries, it
follows a short review on how to work with them and debug their usage.


### Environment variables

A method to ensure that shared libraries located in a certain folder are found,
is to export the system environment variable **LD_LIBRARY_PATH**.  In the
example below, the environment variable gets extended by the path */opt/lib*.

```
export LD_LIBRARY_PATH=/opt/lib:$LD_LIBRARY_PATH
./run-your-program
```

Another **very verbose** method to figure out what shared libraries your system
is actually loading and at which paths your system is looking for them, is
exporting the system environment variable **LD_DEBUG**:

```
export LD_DEBUG={files|bindings|libs|versions|help}
./run-your-program
```

The meaning of the individual values of *LD_DEBUG* can be found in [1] (see
below).

### Useful tools

Some useful tools for checking the shared library dependencies of a program or
library or whether the "right" shared library was loaded at runtime by a
program are:

- [ld](http://linux.die.net/man/1/ld) - The GNU linker
- [ldd](http://linux.die.net/man/1/ldd) - print shared library dependencies
- [nm](http://linux.die.net/man/1/nm) - list symbols from object files
- [objdump](http://linux.die.net/man/1/objdump) - display information from
  object files
- [pmap](http://linux.die.net/man/1/pmap) - report memory map of a process
- [readelf](http://linux.die.net/man/1/readelf) - Displays information about
  ELF files.

Assume your program binary is called `<PROG>` and at runtime it has the process
ID `<PID>` (which can for example be found out with `pgrep -l octave`) and a
shared library of interest is called `<LIB>`, then the commands can be used as
follows:

```
ldd        {<PROG>|<LIB>}
nm -D      {<PROG>|<LIB>}
objdump    {<PROG>|<LIB>}
readelf -d {<PROG>|<LIB>}
pmap       <PID>
```

To get a further insight into shared libraries, here are some more advanced
references on this topic:

- [1] http://tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html
- [2] http://www.yolinux.com/TUTORIALS/LibraryArchives-StaticAndDynamic.html
- [3] http://www.ibm.com/developerworks/library/l-dynamic-libraries
