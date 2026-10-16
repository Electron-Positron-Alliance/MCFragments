# Herwig 7.1.5: LEP1 qqbar, ISR off / on

In the C_ISR systematic envelope. Platform: see the top-level `README.md`.

Files: `lep1_isr0.in`, `lep1_isr1.in`, `run_isr.sh`, `env.sh`, `hepmcToRoot.cc` + `Makefile` (HepMC2 -> `tgenBefore`
ntuple; the same converter as `SHERPA2/LEP1_qqbar_ISR`).

ISR off: `NoPDF` for e+/e- + `ShowerHandler:DoISR No`; ISR on: `LeptonPDF` + `DoISR Yes`. sqrt(s) = 91.188 GeV.

| Package | Version | File | sha256 |
|---|---|---|---|
| Herwig | 7.1.5 | `Herwig-7.1.5.tar.bz2` | `3965a6ac5eb48e7546578c2a30013f70caf2a3da23e37b067b8128f753d9d94a` |
| ThePEG | 2.1.5 | `ThePEG-2.1.5.tar.bz2` | `c61a00fb6cf406f0f98e8c934683d8d5efcb655747842113abc92e9526e4b5e6` |
| HepMC2 | 2.06.11 | `hepmc2.06.11.tgz` | `86b66ea0278f803cde5774de8bd187dd42c870367f1cbf6cdaec8dc7cf6afc10` |
| LHAPDF | 6.3.0 | `LHAPDF-6.3.0.tar.gz` | `ed4d8772b7e6be26d1a7682a13c87338d67821847aa1640d78d67d2cef8b9b5d` |
| FastJet | 3.3.4 | `fastjet-3.3.4.tar.gz` | `432b51401e1335697c9248519ce3737809808fc1f6d1644bfae948716dddfc03` |
| CLHEP | 2.4.5.1 | `clhep-2.4.5.1.tgz` | `2517c9b344ad9f55974786ae6e7a0ef8b22f4abcbf506df91194ea2299ce3813` |
| Boost | 1.75.0 | `boost_1_75_0.tar.bz2` | `953db31e016db7bb207f11432bef7df100516eeb746843fa0486a222e3fd49cb` |

LHAPDF sets installed: `MMHT2014lo68cl`, `MMHT2014nlo68cl`. GSL is the system package.

Build (prefix `P=/home/badea/code/herwig715`; every dependency is installed into that prefix):
```sh
# CLHEP 2.4.5.1 (cmake), Boost 1.75.0 (filesystem, system, test libraries; b2 options not recorded),
# LHAPDF 6.3.0 (flags not recorded for this prefix; the Sherpa 2.2.6 prefix used --disable-python)
<fastjet-3.3.4>/configure --prefix=$P --enable-shared
<HepMC-2.06.11>/configure --prefix=$P --with-momentum=GEV --with-length=MM
<ThePEG-2.1.5>/configure --prefix=$P --with-clhep=$P --with-hepmc=$P --with-fastjet=$P --with-lhapdf=$P --with-boost=$P --with-gsl=<gsl-stub>
<Herwig-7.1.5>/configure --prefix=$P --with-thepeg=$P --with-fastjet=$P --with-boost=$P --with-gsl=<gsl-stub>
# <gsl-stub>: include/gsl -> /usr/include/gsl, lib64/libgsl.a -> /usr/lib64/libgsl.so, lib64/libgslcblas.a -> /usr/lib64/libgslcblas.so
```

Run:
```sh
source env.sh
Herwig read lep1_isr0.in; Herwig read lep1_isr1.in
make
for S in 0 1; do for j in $(seq 1 10); do
  Herwig run lep1_isr$S.run -N 500000 -s $j     # writes lep1_isr$S-S$j.hepmc
  ./hepmcToRoot -f lep1_isr$S-S$j.hepmc -o herwig715_isr${S}_$((j-1)).root
done; done
```
Shard `i` (0-9) = seed `i+1`, same seeds for isr0 and isr1. `run_isr.sh` as written runs only seeds 1-5; seeds 6-10
were run the same way.

Known difference: `hepmcToRoot.cc` was edited on 2026-03-27, after the 2026-03-21/22 ntuples were made. The current
version leaves the `pwflag` branch unfilled, while the archived ntuples have it filled. The analysis derives `pwflag`
from `pdgid` itself (`pwflagFromPdgId` in `Analyze.cxx`).

## Verification (2026-10-08)

`Herwig read` of these `.in` files; 100 events of isr1 seed 1 and 50 events of isr0 seed 10 give the same events as
the archived shards, floats agreeing to 6e-15 relative. The same float differences appear when the original Herwig
`.run` file is rerun today, so they are not caused by these cards.
