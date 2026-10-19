#!/bin/bash
# PHOTOS++ 3.64 -> $MCF_PREFIX/local/photos (used by KKMCee). Needs HepMC3 (setup_hepmc3.sh).
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
"$HERE/fetch.sh" PHOTOS.3.64.tar.gz
cd "$MCF_PREFIX/src"
rm -rf PHOTOS
tar xzf PHOTOS.3.64.tar.gz
cd PHOTOS
./configure --with-hepmc3="$MCF_PREFIX/local" --without-hepmc --prefix="$MCF_PREFIX/local/photos" CXXFLAGS="-std=c++11 -g -O2"
make
make install
