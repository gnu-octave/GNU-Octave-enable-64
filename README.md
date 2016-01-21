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

- [OpenBLAS](http://www.openblas.net) (0.2.15),
- [SuiteSparse](http://www.suitesparse.com) (4.4.7),
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
this project requires approximately **4 GB** disc space, and **2 hours**,
depending on your system.

Using this Makefile is especially of interest, if one pursues the following
goals:

1. No root privileges required.
2. No collision with system libraries.

Both abovementioned goals are archived by building and deploying the required
libraries in an arbitrary directory **ROOT_DIR**.  The internal directory
structure is:

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
     |-- octave    # GNU Octave Mercurial repository
     |-- arpack-$(VER).tar.gz
     +--  ...
```

All required libraries are built according to a similar pattern:

1. Download the source code
2. Extract the source code to directory *ROOT_DIR/build*
3. Do required configurations regarding 64-bit indices
4. Build the library
5. Add the suffix "_Octave64" to the library's
   [SONAME](https://en.wikipedia.org/wiki/Soname)
6. Deploy the library in *ROOT_DIR/libs/lib*

To guarantee the usage of the self compiled libraries, even in presence of
a system wide installed substitute, the library's
[SONAME](https://en.wikipedia.org/wiki/Soname) is changed to enforce a hard
error if the "wrong" library is taken.  Therefore it would even be possible
to deploy the self compiled libraries system wide.  For more information on
shared libraries in common Linux distributions, the the subsection below.

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


## Shared libraries

As all of this project deals with the correct treatment of shared libraries, it
follows a collection of really must read articles regarding this topic:

- [tldp.org](http://tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html)
- [yolinux.com](http://www.yolinux.com/TUTORIALS/LibraryArchives-StaticAndDynamic.html)


## Debugging

Here some useful tools for checking whether the right library was loaded or
not.  To check the loaded shared libraries, try

```
pmap <PID>
pldd <PID>
```

where <PID> is the process ID of the current octave. Statically you can use

```
ldd src/octave
readelf -d src/octave
```

to find out the starting shared library dependencies.
