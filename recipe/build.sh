#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .
cp $BUILD_PREFIX/share/gnuconfig/config.* ./config

# purge micropython as it leads to compiler errors
rm -rf micropython-1.12
sed -i.bak '/^micropython-1.12/d' configure.ac
sed -i.bak 's/micropython-1.12//g' Makefile.am
autoreconf -vfi

# giac vendors a version of quickjs that uses fesetround which needs C99
export CFLAGS="-O2 -g $CFLAGS -std=c99"
export CXXFLAGS="-O2 -g $CXXFLAGS"

# Need this due to use of register
export CXXFLAGS=$(echo "${CXXFLAGS}" | sed "s/-std=c++17//g")
export CXXFLAGS=$(echo "${CXXFLAGS}" | sed "s/-std=c++14//g")
export CXXFLAGS="$CXXFLAGS -std=c++11"

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
./configure --prefix="$PREFIX" --disable-gui --disable-ao --disable-static --disable-samplerate --disable-micropy

make -j${CPU_COUNT}
# Enable the following once https://github.com/conda/conda-build/issues/1797 is fixed.
# Enable patches/nofltk-check.patch as well
# make check -j${CPU_COUNT}
make install
