# GNU Octave enable-64

This project targets compiling [GNU Octave](http://www.gnu.org/software/octave/)
using 64-bit indices on Linux systems.  This project is greatly inspired by
similar works (see section below).


## Similar works

This project is greatly inspired by a
[blog post by Richard Calaba](http://calaba.tumblr.com/post/107087607479/octave-64),
who has also created one year ahead a
[GitHub](https://github.com/calaba/octave-3.8.2-enable-64-ubuntu-14.04)
repository for GNU Octave 3.8.

For Windows, there is the already working
[MXE-Octave](http://wiki.octave.org/MXE) cross-compiling solution.  It compiles
really everything from scratch.


## Shared libraries

As all of this project deals with the correct treatment of shared libraries, it
follows a collection of really must read articles regarding this topic:

- [tldp.org](http://tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html)
- [yolinux.com](http://www.yolinux.com/TUTORIALS/LibraryArchives-StaticAndDynamic.html)

https://www.gnu.org/software/octave/doc/interpreter/Compiling-Octave-with-64_002dbit-Indexing.html


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
