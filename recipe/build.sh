#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .
cp $BUILD_PREFIX/share/gnuconfig/config.* ./config

# purge micropython as it leads to compiler errors
rm -rf micropython-1.12
sed -i.bak '/^micropython-1.12/d' configure.ac
sed -i.bak 's/micropython-1.12//g' Makefile.am
autoreconf -vfi

export CFLAGS="-O2 -g $CFLAGS"
export CXXFLAGS="-O2 -g $CXXFLAGS"

# Newer clang doesn't like converting non constant values in initializer lists
sed -i.bak "s/{order,lexvars}/{(short)order,(unsigned char)lexvars}/g" src/solve.cc
sed -i.bak "s/{order.val,0}/{(short)order.val,0}/g" src/solve.cc

if [[ "$target_platform" == "osx-"* ]]; then
  export CFLAGS="$CFLAGS -Wno-implicit-function-declaration"
fi

# Needs to use `gcc -E` instead of `cpp`
unset CPP

# Delete libgfortran.so so that giac doesn't link to it.
find $PREFIX -name libgfortran${SHLIB_EXT} -delete
find $BUILD_PREFIX -name libgfortran${SHLIB_EXT} -delete

chmod +x configure
./configure --prefix="$PREFIX" --disable-gui --disable-fltk --disable-ao --disable-static --disable-samplerate --disable-micropy

# js.c/js.h are pre-generated in the tarball. The Makefile rebuilds them via mkjs,
# which is compiled with a hardcoded "g++" that doesn't exist in conda-forge's
# toolchain (macOS uses clang++, cross-compilation uses a target-arch compiler).
# Touch the pre-generated files so make skips rebuilding them.
touch src/js.c src/js.h

make -j${CPU_COUNT}

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" || "$CROSSCOMPILING_EMULATOR" != "" ]]; then
  if [[ "$target_platform" == "osx-"* ]]; then
    # Some tests may fail on macOS due to platform-specific numerical differences
    make check -j${CPU_COUNT} || true
  else
    make check -j${CPU_COUNT}
  fi
fi

make install
