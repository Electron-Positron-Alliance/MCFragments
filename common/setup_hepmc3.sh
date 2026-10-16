#!/bin/bash
# HepMC3 3.2.5 -> $MCF_PREFIX/local (used by KKMCee, KORALZ and Sherpa 3).
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
"$HERE/fetch.sh" HepMC3-3.2.5.tar.gz
cd "$MCF_PREFIX/src"
rm -rf HepMC3-3.2.5 HepMC3-build
tar xzf HepMC3-3.2.5.tar.gz
cmake -S HepMC3-3.2.5 -B HepMC3-build -DCMAKE_INSTALL_PREFIX="$MCF_PREFIX/local" -DHEPMC3_ENABLE_ROOTIO=OFF \
  -DHEPMC3_ENABLE_PYTHON=OFF -DHEPMC3_ENABLE_TEST=OFF -DHEPMC3_BUILD_EXAMPLES=OFF -DHEPMC3_BUILD_DOCS=OFF
cmake --build HepMC3-build -j "${MCF_JOBS:-$(nproc)}"
cmake --install HepMC3-build
