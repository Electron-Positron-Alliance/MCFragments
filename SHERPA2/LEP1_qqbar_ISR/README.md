# Sherpa 2.2.6: LEP1 qqbar, ISR off / on

Cards: `Run_isr0.dat`, `Run_isr1.dat`. ISR off: `PDF_LIBRARY None`; ISR on: `BUNCH_1 11; BUNCH_2 -11`, i.e. the
electron structure function (leading log, collinear: one photon per beam with zero pT). YFS (Photons++) in Sherpa 2.2.6
acts on decays only, so it does not add ISR here. sqrt(s) = 91.188 GeV. The HepMC2 -> `tgenBefore` converter is
`common/hepmcToRoot.cc`, shared with `HERWIG7/LEP1_qqbar_ISR`. Install layout and prerequisites: see the top-level
`README.md`.

## Files

| File | What it is |
|---|---|
| `Run_isr0.dat`, `Run_isr1.dat` | the cards (ISR off / on) |
| `setup.sh` | downloads and builds Sherpa 2.2.6 and all its dependencies, makes the run directory |
| `run_production.sh` | runs all 20 jobs, or a subset |
| `env.sh` | runtime environment, sourced by the scripts |
| `patches/` | GCC 11 compile fix for Sherpa |

## Set up

```sh
export MCF_PREFIX=<install root>
SHERPA2/LEP1_qqbar_ISR/setup.sh          # -> $MCF_PREFIX/sherpa226 and $MCF_PREFIX/sherpa226/run
```
`setup.sh` builds Sherpa and its dependencies (versions in its header, sources in `common/sources.txt`) into
`$MCF_PREFIX/sherpa226`, and applies the GCC 11 compile fix in `patches/` to Sherpa.

## Run

```sh
SHERPA2/LEP1_qqbar_ISR/run_production.sh     # 20 jobs, MAXPAR (default 20) at a time
```
Seeds, file names and overrides: see the header of `run_production.sh`, which also explains why every job starts from
an empty directory.

Known differences from the archived ntuples:
- Shards 0-4 (both ISR states) were converted before the 2026-03-21 16:27 rebuild of `hepmcToRoot`, by a version
  whose source was not kept. In those shards `sqrt_sHat` and `mHat` are 91.188 for every event, while this converter
  writes the hadronic mass when there is no Z in the record. ISR-on shards 5-9 already use this converter's definition.
  Per-particle `mass` (up to 4e-5 GeV on near-massless particles) and `y` of beam-collinear particles (|y| ~ 12) also
  differ slightly. The analysis reads `mass` but not `sqrt_sHat`, `mHat` or `y`.
- `hepmcToRoot.cc` was edited on 2026-03-27, after the ntuples were made: it leaves the `pwflag` branch unfilled, while
  the archived ntuples have it filled. The analysis derives `pwflag` from `pdgid` itself.

Production build environment: LHAPDF and Sherpa were configured inside a conda environment, which added its compiler
flags (`-march=nocona -mtune=haswell -ftree-vectorize -O2 ...`, plus `-isystem` to the conda include directory).
`setup.sh` does not reproduce that environment; a fresh build with default flags gives the same events.

## Reference values

To check a new installation, run 1000 events of shard 0 and compare the output of `common/summarize.C` with the lines
below. They equal the first 1000 events of the production shards 0, so a matching installation reproduces the
production.
```sh
NEVENTS=1000 SEEDS=1 SHERPA2/LEP1_qqbar_ISR/run_production.sh
root -l -b -q "common/summarize.C(\"$MCF_PREFIX/sherpa226/run/sherpa226_isr0_0.root\")"
```
```
sherpa226_isr0_0          events 1000  thrust(event 0) 0.968882  <thrust> 0.935914  <nParticle> 87.6440  <sum isCharged> 36.2830
sherpa226_isr1_0          events 1000  thrust(event 0) 0.942853  <thrust> 0.933481  <nParticle> 90.7430  <sum isCharged> 36.4250
```
