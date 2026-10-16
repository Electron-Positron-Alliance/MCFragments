# Herwig 7.1.5: LEP1 qqbar, ISR off / on

In the C_ISR systematic envelope. Install layout and prerequisites: see the top-level `README.md`.

Files: `lep1_isr0.in`, `lep1_isr1.in` (the cards), `setup.sh`, `run_production.sh`, `env.sh`, `hepmcToRoot.cc` +
`Makefile` (HepMC2 -> `tgenBefore` ntuple; the same converter as `SHERPA2/LEP1_qqbar_ISR`), and `patches/` (GCC 11
compile fixes for ThePEG, Herwig and CLHEP).

ISR off: `NoPDF` for e+/e- + `ShowerHandler:DoISR No`; ISR on: `LeptonPDF` + `DoISR Yes`. Hard process: Herwig's
built-in `MEee2gZ2qq`. sqrt(s) = 91.188 GeV.

## Set up

```sh
export MCF_PREFIX=<install root>
HERWIG7/LEP1_qqbar_ISR/setup.sh          # -> $MCF_PREFIX/herwig715 and $MCF_PREFIX/herwig715/run
```
`setup.sh` downloads (URLs and sha256 in `common/sources.txt`) and installs into the one prefix `$MCF_PREFIX/herwig715`:

| Package | Version | Build |
|---|---|---|
| Boost | 1.75.0 | `./bootstrap.sh --with-libraries=test,filesystem,system`, `./b2 install` |
| CLHEP | 2.4.5.1 | GCC 11 patch; cmake, `CMAKE_BUILD_TYPE=Release` |
| FastJet | 3.3.4 | `configure --enable-shared` |
| HepMC | 2.06.11 | `configure --with-momentum=GEV --with-length=MM` |
| LHAPDF | 6.3.0 | `configure --disable-python`; PDF sets `MMHT2014lo68cl`, `MMHT2014nlo68cl` |
| ThePEG | 2.1.5 | GCC 11 patch; `configure --with-clhep --with-hepmc --with-fastjet --with-lhapdf --with-boost --with-gsl` (all = the prefix; GSL via a stub, below) |
| Herwig | 7.1.5 | GCC 11 patch; `configure --with-thepeg --with-fastjet --with-boost --with-gsl FCFLAGS=-fallow-argument-mismatch` (Looptools Fortran, gfortran >= 10) |

ThePEG and Herwig look for `libgsl.a` / `libgslcblas.a` under the `--with-gsl` prefix, so `setup.sh` makes a stub
(`include/gsl -> /usr/include/gsl`, `lib64/libgsl.a -> /usr/lib64/libgsl.so`, `lib64/libgslcblas.a ->
/usr/lib64/libgslcblas.so`) pointing at the system GSL. Finally it copies the cards and the converter into
`$MCF_PREFIX/herwig715/run` and builds `hepmcToRoot` there (system ROOT, `root-config` from PATH).

## Run

```sh
HERWIG7/LEP1_qqbar_ISR/run_production.sh     # 20 jobs, MAXPAR (default 20) at a time
```
In `$MCF_PREFIX/herwig715/run`: `Herwig read lep1_isr$S.in`, then for shard `i` (0-9) `Herwig run lep1_isr$S.run
-N 500000 -s $((i+1))` (the same seeds for isr0 and isr1), which writes `lep1_isr$S-S$((i+1)).hepmc` (kept), and
`hepmcToRoot` -> `herwig715_isr${S}_${i}.root`. `NEVENTS`, `SEEDS` and `STATES` select fewer events, seeds or states.

Known difference: `hepmcToRoot.cc` was edited on 2026-03-27, after the 2026-03-21/22 ntuples were made. The current
version leaves the `pwflag` branch unfilled, while the archived ntuples have it filled. The analysis derives `pwflag`
from `pdgid` itself (`pwflagFromPdgId` in `Analyze.cxx`).

Production build environment: ThePEG, Herwig and LHAPDF were configured inside a conda environment, which added its
compiler flags (`-march=nocona -mtune=haswell -ftree-vectorize -O2 ...`, plus `-isystem` to the conda include
directory). `setup.sh` does not reproduce that environment; the fresh build below, with default flags, gives the same
events.

## Reference values

To check a new installation, run 1000 events of shard 0 and compare the output of `common/summarize.C` with the lines
below (fresh build, 2026-10-16). These equal the first 1000 events of the production shards 0 (checked 2026-10-16), so a
matching installation reproduces the production.
```sh
NEVENTS=1000 SEEDS=1 HERWIG7/LEP1_qqbar_ISR/run_production.sh
root -l -b -q "common/summarize.C(\"$MCF_PREFIX/herwig715/run/herwig715_isr0_0.root\")"
```
```
herwig715_isr0_0  events 1000  thrust(event 0) 0.976836  <thrust> 0.930593  <nParticle> 105.3160  <sum isCharged> 40.3450
herwig715_isr1_0  events 1000  thrust(event 0) 0.981746  <thrust> 0.933084  <nParticle> 110.4750  <sum isCharged> 44.0020
```

## Verification (2026-10-16)

Fresh build from `setup.sh` into an empty `MCF_PREFIX`; `run_production.sh` with `NEVENTS=100` for isr1 seed 1 and
`NEVENTS=50` for isr0 seed 10, against the archived shards 0 and 9: identical momenta, energies, PDG ids, status codes
and relations. The only differences: `pwflag` (above) and the `mass` of 7 photons, by at most 3.5e-8 GeV.
