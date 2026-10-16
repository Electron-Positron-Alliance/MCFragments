#!/bin/bash
# KKMCee (git bf3cce7) + MainHepMC + hadronizeKKMC + the 5-quark DIZET table -> $MCF_PREFIX/kkmcee.
# Needs common/setup_root.sh, setup_hepmc3.sh, setup_photospp.sh and PYTHIA8/LEP1_qqbar_ISR/setup.sh (hadronizeKKMC
# links PYTHIA 8.317), plus the system ROOT 6.38.04. Run with prodrun/run_production.sh.
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
K=$MCF_PREFIX/kkmcee
L=$MCF_PREFIX/local
P8=$MCF_PREFIX/pythia8317
R6=$MCF_PREFIX/root

rm -rf "$K"
git clone https://github.com/KrakowHEPSoft/KKMCee "$K"
cd "$K"
git checkout -q bf3cce7f4326c34de81a39daf30fadbb6836bd94
ln -f -s dizet-6.45 dizet   # the electroweak library version (KKMCee README; dizet-6.42 and 6.21 also ship)
( set +u; source "$R6/bin/thisroot.sh"; set -u
  autoreconf -f -i
  ./configure CXXFLAGS="-std=c++17 -g -O2" --with-hepmc="$L" --with-photos="$L/photos"
  make -j "${MCF_JOBS:-$(nproc)}" )

cp -r "$HERE"/prodrun/* ProdRun/
cd ProdRun
# MainHepMC: compiled against the ROOT 6.36.04 release, run against the system ROOT (prodrun/setup_kkmc_env.sh).
RL="-L$R6/lib -lGui -lCore -lImt -lRIO -lNet -lHist -lGraf -lGraf3d -lGpad -lROOTVecOps -lTree -lTreePlayer -lRint -lPostscript -lMatrix -lPhysics -lMathCore -lThread -lROOTNTuple -lMultiProc -lROOTDataFrame -lROOTNTupleUtil"
g++ -std=c++17 -g -O2 -I"$K" -I"$K/SRCee" -I"$K/MCdev" -I"$K/Foam2" -I"$R6/include" -I"$L/include" \
  -I"$L/photos/include" MainHepMC.cxx -o MainHepMC \
  -L"$K/SRCee/.libs" -lKKee -L"$K/tauola-photos/.libs" -lTauolaPhotos -L"$K/MCdev/.libs" -lMCdev -L"$K/Foam2/.libs" -lFOAM $RL \
  -L"$L/photos/lib" -lPhotosppHepMC3 -lPhotosppHEPEVT -lPhotospp -L"$L/lib64" -lHepMC3 -lgfortran -lquadmath \
  -Wl,-rpath,"$L/lib64:$K/SRCee/.libs:$K/tauola-photos/.libs:$K/MCdev/.libs:$K/Foam2/.libs:$L/photos/lib"
# hadronizeKKMC: PYTHIA 8.317 FSR + hadronization, system ROOT 6.38.04.
g++ -std=c++17 -O2 hadronizeKKMC.cc -o hadronizeKKMC -I"$P8/include" -I"$L/include" $(/usr/bin/root-config --cflags) \
  -L"$P8/lib" -lpythia8 -L"$L/lib64" -lHepMC3 $(/usr/bin/root-config --libs) \
  -Wl,-rpath,"/usr/lib64/root:$P8/lib:$L/lib64"

# The DIZET electroweak table every shard reads (2 s).
cd workQQ2_dizet
ln -sf ../../SRCee/KKMCee_defaults KKMCee_defaults
( source ../setup_kkmc_env.sh && ../../DZface/TabMainC > tab.log 2>&1 )
echo "28788f8f7a8ff36db89658a6b869c95944f1fe8d3546d8658fbd243725cdcf49  DIZET-table1" | sha256sum -c --quiet - \
  || { echo "setup.sh: DIZET-table1 differs from the production table" >&2; exit 1; }
echo "setup.sh: KKMCee ready in $K/ProdRun"
