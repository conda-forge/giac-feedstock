#!/bin/bash

export CFLAGS="-O2 -g $CFLAGS"
export CXXFLAGS="-O2 -g $CXXFLAGS"

export CXXFLAGS=$(echo "${CXXFLAGS}" | sed "s/-std=c++17/-std=c++11/g")
export CXXFLAGS=$(echo "${CXXFLAGS}" | sed "s/-std=c++14/-std=c++11/g")

chmod +x configure
./configure --prefix="$PREFIX" --disable-gui --disable-ao

make -j${CPU_COUNT}
# Enable the following once https://github.com/conda/conda-build/issues/1797 is fixed.
# Enable patches/nofltk-check.patch as well
# make check -j${CPU_COUNT}
make install
