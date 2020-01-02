#!/bin/bash

export CFLAGS="-O2 -g $CFLAGS"
export CXXFLAGS="-O2 -g $CXXFLAGS"

# Need this due to use of register
export CXXFLAGS=$(echo "${CXXFLAGS}" | sed "s/-std=c++17//g")
export CXXFLAGS=$(echo "${CXXFLAGS}" | sed "s/-std=c++14//g")

# Newer clang doesn't like converting non constant values in initializer lists
sed -i.bak "s/{order,lexvars}/{(short)order,(unsigned char)lexvars}/g" src/solve.cc
sed -i.bak "s/{order.val,0}/{(short)order.val,0}/g" src/solve.cc

if [[ "$CI" == "travis" ]]; then
  export CPU_COUNT=4
fi

# Delete libgfortran.so so that giac doesn't link to it.
find $PREFIX -name libgfortran${SHLIB_EXT} -delete
find $BUILD_PREFIX -name libgfortran${SHLIB_EXT} -delete

chmod +x configure
./configure --prefix="$PREFIX" --disable-gui --disable-ao --disable-static

make -j${CPU_COUNT}
# Enable the following once https://github.com/conda/conda-build/issues/1797 is fixed.
# Enable patches/nofltk-check.patch as well
# make check -j${CPU_COUNT}
make install
