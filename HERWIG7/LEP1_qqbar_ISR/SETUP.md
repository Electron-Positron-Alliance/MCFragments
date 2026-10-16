# Herwig 7.1.5: LEP1 qqbar, ISR off / on

Cards: `lep1_isr0.in`, `lep1_isr1.in`. ISR off: `NoPDF` for e+/e- + `ShowerHandler:DoISR No`; ISR on: `LeptonPDF` +
`DoISR Yes`. Hard process: Herwig's built-in `MEee2gZ2qq`. sqrt(s) = 91.188 GeV. The HepMC2 -> `tgenBefore` converter
is `common/hepmcToRoot.cc`, shared with `SHERPA2/LEP1_qqbar_ISR`. Install layout and prerequisites: see the top-level
`README.md`.

## Set up

```sh
export MCF_PREFIX=<install root>
HERWIG7/LEP1_qqbar_ISR/setup.sh          # -> $MCF_PREFIX/herwig715 and $MCF_PREFIX/herwig715/run
```
`setup.sh` builds the whole dependency chain (versions in its header, sources in `common/sources.txt`) into the one
prefix `$MCF_PREFIX/herwig715`, and applies the GCC 11 compile fixes in `patches/` to ThePEG and Herwig.

## Run

```sh
HERWIG7/LEP1_qqbar_ISR/run_production.sh     # 20 jobs, MAXPAR (default 20) at a time
```
Seeds, file names and overrides: see the header of `run_production.sh`.

Known difference: `hepmcToRoot.cc` was edited on 2026-03-27, after the 2026-03-21/22 ntuples were made. The current
version leaves the `pwflag` branch unfilled, while the archived ntuples have it filled. The analysis derives `pwflag`
from `pdgid` itself.

Production build environment: ThePEG, Herwig and LHAPDF were configured inside a conda environment, which added its
compiler flags (`-march=nocona -mtune=haswell -ftree-vectorize -O2 ...`, plus `-isystem` to the conda include
directory). `setup.sh` does not reproduce that environment; a fresh build with default flags gives the same events.

## Reference values

To check a new installation, run 1000 events of shard 0 and compare the output of `common/summarize.C` with the lines
below. They equal the first 1000 events of the production shards 0, so a matching installation reproduces the
production.
```sh
NEVENTS=1000 SEEDS=1 HERWIG7/LEP1_qqbar_ISR/run_production.sh
root -l -b -q "common/summarize.C(\"$MCF_PREFIX/herwig715/run/herwig715_isr0_0.root\")"
```
```
herwig715_isr0_0  events 1000  thrust(event 0) 0.976836  <thrust> 0.930593  <nParticle> 105.3160  <sum isCharged> 40.3450
herwig715_isr1_0  events 1000  thrust(event 0) 0.981746  <thrust> 0.933084  <nParticle> 110.4750  <sum isCharged> 44.0020
```
