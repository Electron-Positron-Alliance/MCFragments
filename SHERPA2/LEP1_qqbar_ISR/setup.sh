#!/bin/bash
# Sherpa 2.2.6 and its dependencies -> $MCF_PREFIX/sherpa226: FastJet 3.3.4, HepMC 2.06.11, LHAPDF 6.3.0 + PDF sets,
# Sherpa 2.2.6 (with the GCC 11 compile fix in patches/). Also the cards and the HepMC2 -> ntuple converter in
# $MCF_PREFIX/sherpa226/run. Sources are unpacked in $MCF_PREFIX/src/sherpa226-build. Run with run_production.sh.
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
P=$MCF_PREFIX/sherpa226
J=${MCF_JOBS:-$(nproc)}
"$HERE/../../common/fetch.sh" fastjet-3.3.4.tar.gz hepmc2.06.11.tgz LHAPDF-6.3.0.tar.gz MMHT2014lo68cl.tar.gz \
  MMHT2014nlo68cl.tar.gz SHERPA-MC-2.2.6.tar.gz
rm -rf "$P"
W=$MCF_PREFIX/src/sherpa226-build
rm -rf "$W" && mkdir -p "$W" && cd "$W"
for t in fastjet-3.3.4.tar.gz hepmc2.06.11.tgz LHAPDF-6.3.0.tar.gz SHERPA-MC-2.2.6.tar.gz; do tar xzf "$MCF_PREFIX/src/$t"; done

mkdir build_fastjet && (cd build_fastjet && ../fastjet-3.3.4/configure --prefix="$P" --enable-shared && make -j "$J" && make install)
mkdir build_hepmc2 && (cd build_hepmc2 && ../HepMC-2.06.11/configure --prefix="$P" --with-momentum=GEV --with-length=MM && make -j "$J" && make install)
(cd LHAPDF-6.3.0 && ./configure --prefix="$P" --disable-python && make -j "$J" && make install)
for set in MMHT2014lo68cl MMHT2014nlo68cl; do tar xzf "$MCF_PREFIX/src/$set.tar.gz" -C "$P/share/LHAPDF"; done
(cd SHERPA-MC-2.2.6 && patch -p1 < "$HERE/patches/SHERPA-MC-2.2.6-gcc11.patch" \
  && ./configure --prefix="$P" --enable-hepmc2="$P" --enable-lhapdf="$P" --enable-gzip=no --enable-mpi=no \
  && make -j "$J" && make install)

# Run directory: the cards and the HepMC2 -> ntuple converter (common/hepmcToRoot.cc, system ROOT 6.38.04).
mkdir -p "$P/run"
cp "$HERE"/Run_isr0.dat "$HERE"/Run_isr1.dat "$P/run/"
g++ -O2 -std=c++14 -Wall -I"$P/include" $(/usr/bin/root-config --cflags) -o "$P/run/hepmcToRoot" \
  "$HERE/../../common/hepmcToRoot.cc" -L"$P/lib" -Wl,-rpath,"$P/lib" -lHepMC $(/usr/bin/root-config --libs)
echo "setup.sh: Sherpa 2.2.6 ready; run with $HERE/run_production.sh"
