#!/bin/bash
# Herwig 7.1.5 and its dependency chain -> $MCF_PREFIX/herwig715, plus the cards and the HepMC2 -> ntuple converter in
# $MCF_PREFIX/herwig715/run. Every dependency goes into the one prefix, in this order: Boost 1.75.0, CLHEP 2.4.5.1,
# FastJet 3.3.4, HepMC 2.06.11, LHAPDF 6.3.0 + PDF sets, ThePEG 2.1.5, Herwig 7.1.5. ThePEG, Herwig and CLHEP carry the
# GCC 11 compile fixes in patches/; Herwig's Looptools Fortran also needs FCFLAGS=-fallow-argument-mismatch with
# gfortran >= 10. Run with run_production.sh.
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
P=$MCF_PREFIX/herwig715
S=$MCF_PREFIX/src
J=${MCF_JOBS:-$(nproc)}
"$HERE/../../common/fetch.sh" boost_1_75_0.tar.bz2 clhep-2.4.5.1.tgz fastjet-3.3.4.tar.gz hepmc2.06.11.tgz \
  LHAPDF-6.3.0.tar.gz MMHT2014lo68cl.tar.gz MMHT2014nlo68cl.tar.gz ThePEG-2.1.5.tar.bz2 Herwig-7.1.5.tar.bz2
rm -rf "$P"
B=$S/build_herwig715
rm -rf "$B"
mkdir -p "$B"
cd "$S"

rm -rf boost_1_75_0 && tar xjf boost_1_75_0.tar.bz2
(cd boost_1_75_0 && ./bootstrap.sh --prefix="$P" --with-libraries=test,filesystem,system && ./b2 -j "$J" install)

rm -rf 2.4.5.1 && tar xzf clhep-2.4.5.1.tgz
(cd 2.4.5.1/CLHEP && patch -p1 < "$HERE/patches/CLHEP-2.4.5.1-gcc11.patch")
cmake -S 2.4.5.1/CLHEP -B "$B/clhep" -DCMAKE_INSTALL_PREFIX="$P" -DCMAKE_BUILD_TYPE=Release
cmake --build "$B/clhep" -j "$J" && cmake --install "$B/clhep"

rm -rf fastjet-3.3.4 && tar xzf fastjet-3.3.4.tar.gz
mkdir -p "$B/fastjet" && (cd "$B/fastjet" && "$S/fastjet-3.3.4/configure" --prefix="$P" --enable-shared && make -j "$J" && make install)

rm -rf HepMC-2.06.11 && tar xzf hepmc2.06.11.tgz
mkdir -p "$B/hepmc2" && (cd "$B/hepmc2" && "$S/HepMC-2.06.11/configure" --prefix="$P" --with-momentum=GEV --with-length=MM && make -j "$J" && make install)

rm -rf LHAPDF-6.3.0 && tar xzf LHAPDF-6.3.0.tar.gz
(cd LHAPDF-6.3.0 && ./configure --prefix="$P" --disable-python && make -j "$J" && make install)
for set in MMHT2014lo68cl MMHT2014nlo68cl; do tar xzf "$set.tar.gz" -C "$P/share/LHAPDF"; done

# ThePEG/Herwig find GSL through a prefix with libgsl.a / libgslcblas.a; point it at the system GSL.
G=$S/gsl-stub
rm -rf "$G" && mkdir -p "$G/include" "$G/lib64"
ln -s /usr/include/gsl "$G/include/gsl"
ln -s /usr/lib64/libgsl.so "$G/lib64/libgsl.a"
ln -s /usr/lib64/libgslcblas.so "$G/lib64/libgslcblas.a"

source "$HERE/env.sh"
rm -rf ThePEG-2.1.5 && tar xjf ThePEG-2.1.5.tar.bz2
(cd ThePEG-2.1.5 && patch -p1 < "$HERE/patches/ThePEG-2.1.5-gcc11.patch" \
  && ./configure --prefix="$P" --with-clhep="$P" --with-hepmc="$P" --with-fastjet="$P" --with-lhapdf="$P" --with-boost="$P" --with-gsl="$G" \
  && make -j "$J" && make install)
rm -rf Herwig-7.1.5 && tar xjf Herwig-7.1.5.tar.bz2
(cd Herwig-7.1.5 && patch -p1 < "$HERE/patches/Herwig-7.1.5-gcc11.patch" \
  && ./configure --prefix="$P" --with-thepeg="$P" --with-fastjet="$P" --with-boost="$P" --with-gsl="$G" \
       FCFLAGS=-fallow-argument-mismatch \
  && make -j "$J" && make install)

# Run directory: the cards and the converter (built against the system ROOT, root-config from PATH).
mkdir -p "$P/run"
cp "$HERE"/lep1_isr0.in "$HERE"/lep1_isr1.in "$HERE"/hepmcToRoot.cc "$HERE"/Makefile "$P/run/"
make -C "$P/run"
echo "setup.sh: Herwig 7.1.5 ready; run with $HERE/run_production.sh"
