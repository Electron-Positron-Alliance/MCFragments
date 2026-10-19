#!/bin/bash
# Sherpa 3.0.5 -> $MCF_PREFIX/sherpa305 (needs common/setup_hepmc3.sh and the system ROOT 6.38.04), plus the run
# directory $MCF_PREFIX/sherpa305/run: the cards, hepmc3ToRoot, and diag_tag/libRemnants.so.0.0.0 for the ISR-on
# keep-all variant (keepall_beamblob_tag.patch, built separately so the installed Sherpa stays unmodified).
# The cmake step downloads libzip v1.9.2 from GitHub. Run with run_production.sh (and run_shard.sh for keep-all).
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
P=$MCF_PREFIX/sherpa305
L=$MCF_PREFIX/local
"$HERE/../../common/fetch.sh" sherpa-v3.0.5.tar.gz
rm -rf "$P"
mkdir -p "$P/src" "$P/run/diag_tag"
cd "$P/src"
tar xzf "$MCF_PREFIX/src/sherpa-v3.0.5.tar.gz"
cmake -S sherpa-v3.0.5 -B build -DCMAKE_INSTALL_PREFIX="$P" -DCMAKE_BUILD_TYPE=Release -DSHERPA_ENABLE_LHAPDF=OFF \
  -DSHERPA_ENABLE_INSTALL_LIBZIP=ON -DSHERPA_ENABLE_HEPMC3=ON -DHepMC3_DIR="$L/share/HepMC3/cmake"
make -C build -j "${MCF_JOBS:-$(nproc)}"
make -C build install

# Keep-all library: patch, rebuild only the Remnants library in the build tree, copy it out, restore the source.
(cd sherpa-v3.0.5 && patch -p1 < "$HERE/keepall_beamblob_tag.patch")
make -C build Remnants
cp build/outputs/lib64/SHERPA-MC/libRemnants.so.0.0.0 "$P/run/diag_tag/"
(cd sherpa-v3.0.5 && patch -R -p1 < "$HERE/keepall_beamblob_tag.patch")
make -C build Remnants

cp "$HERE"/Run_isr0.yaml "$HERE"/Run_isr1.yaml "$HERE"/hepmc3ToRoot.cc "$P/run/"
cd "$P/run"
g++ -O2 -std=c++17 -Wall hepmc3ToRoot.cc -o hepmc3ToRoot -I"$L/include" $(/usr/bin/root-config --cflags) \
  -L"$L/lib64" -Wl,-rpath,"$L/lib64" -lHepMC3 $(/usr/bin/root-config --libs)
echo "setup.sh: Sherpa 3.0.5 ready in $P; run with $HERE/run_production.sh"
