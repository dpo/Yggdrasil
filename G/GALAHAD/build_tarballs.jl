# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GALAHAD"
version = v"4.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ralna/GALAHAD.git", "24bc74a8f7a31762c46ec45897d66fcc3d9e3322"),
    ArchiveSource("https://github.com/ralna/ARCHDefs/archive/refs/tags/v2.0.6.tar.gz", "971ade271c5cf7d1af374579f2b78a1fb69e71b49ea86320ccd605a4f1658ea4"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mv ARCHDefs-2.0.6 ${prefix}/ARCHDefs
export ARCHDEFS=${prefix}/ARCHDefs
export GALAHAD=$PWD/GALAHAD

# install_optrove requires tput
apk update
apk add ncurses

cd $ARCHDEFS
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/helperfunc.patch

# remove paths from systems commands
for f in "system.lnx" "system.osx" "system.mgw"
do
    mv $f ${f}_orig
    sed -e 's/\/usr\/bin\///' ${f}_orig > $f
done
if [[ "${target}" == *-apple* ]]; then
    for f in "compiler.mac64.osx.gfo" "ccompiler.mac64.osx.gcc"
    do
        mv $f ${f}_orig
        sed -e 's/\-12//' ${f}_orig > $f
    end
end

cd $WORKSPACE/srcdir/GALAHAD
# TODO: remove after https://github.com/ralna/GALAHAD/pull/5
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/install.patch

if [[ "${target}" == *-linux* || "${target}" == *-freebsd* ]]; then
    printf "y1\nnnnyn\n6\n3\nn6\nn8\nnyb" > install_config
elif [[ "${target}" == *-apple* ]]; then
    printf "y1\nnnnyn\n6\nn2\nn5\nnyb" > install_config
fi

$ARCHDEFS/bin/install_optrove < install_config
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    # Platform("aarch64", "linux"; libc="glibc"),
    # Platform("armv6l", "linux"; call_abi="eabihf", libc="glibc"),
    # Platform("armv7l", "linux"; call_abi="eabihf", libc="glibc"),
    # Platform("powerpc64le", "linux"; libc="glibc"),
    # Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    # Platform("aarch64", "linux"; libc="musl"),
    # Platform("armv6l", "linux"; call_abi="eabihf", libc="musl"),
    # Platform("armv7l", "linux"; call_abi="eabihf", libc="musl"),
    Platform("x86_64", "macos";),
    Platform("aarch64", "macos";)
]


# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"12.1.0")
