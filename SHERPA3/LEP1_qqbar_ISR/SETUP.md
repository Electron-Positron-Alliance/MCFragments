# Sherpa 3.0.5 (YFS ISR): LEP1 qqbar, ISR off / on

A study sample: drawn beside the C_ISR generators, not in the systematic envelope. It replaces Sherpa 2.2.6's collinear
electron structure function (`SHERPA2/LEP1_qqbar_ISR`) by YFS soft-photon resummation of the ISR.

Files:
- `Run_isr0.yaml`, `Run_isr1.yaml`: the cards. ISR off: `YFS: MODE: Off`; ISR on: `YFS: MODE: ISR`. Both have
  `PDF_LIBRARY: None` and massive electrons (YFS needs them). Otherwise they match the Sherpa 2.2.6 cards: beam energy
  45.594 GeV (sqrt(s) = 91.188 GeV), `ALPHAS(MZ): 0.1188`, process `11 -11 -> 93 93` at EW order 2. Output is native
  HepMC3 (`HEPMC3_IO_TYPE: 0`), because the HepMC2 output contains `-nan` values on which the HepMC2 reader silently
  stops.
- `hepmc3ToRoot.cc`: HepMC3 port of the Sherpa 2.2.6 / Herwig `hepmcToRoot.cc`, same `tgenBefore` tree. `-n N` exits
  with code 2 unless exactly N events were read; `-2` reads HepMC2 input. Beam particles are those with status 4;
  `pwflag` is written as 0 (the analysis derives it from `pdgid`).
- `run_shard.sh`, `run_production.sh`: one shard = one empty work directory, `Sherpa -e 500000 -R J`, then
  `hepmc3ToRoot -n 500000`; the HepMC3 file is deleted only after a full conversion.
- `keepall_beamblob_tag.patch`: the ISR-on keep-all variant (below).
- `setup.sh`.

Source: Sherpa 3.0.5 from gitlab.com/sherpa-team/sherpa (URL and sha256 in `common/sources.txt`). Install layout and
prerequisites: see the top-level `README.md`.

## Set up

```sh
export MCF_PREFIX=<install root>
common/setup_hepmc3.sh                   # once
SHERPA3/LEP1_qqbar_ISR/setup.sh          # -> $MCF_PREFIX/sherpa305 and $MCF_PREFIX/sherpa305/run
```
`setup.sh` runs, in `$MCF_PREFIX/sherpa305/src`:
```sh
cmake -S sherpa-v3.0.5 -B build -DCMAKE_INSTALL_PREFIX=$MCF_PREFIX/sherpa305 -DCMAKE_BUILD_TYPE=Release \
  -DSHERPA_ENABLE_LHAPDF=OFF -DSHERPA_ENABLE_INSTALL_LIBZIP=ON -DSHERPA_ENABLE_HEPMC3=ON \
  -DHepMC3_DIR=$MCF_PREFIX/local/share/HepMC3/cmake
make -C build && make -C build install
```
(`SHERPA_ENABLE_INSTALL_LIBZIP` downloads libzip v1.9.2 from GitHub during the build.) It then builds the keep-all
library (below) into `$MCF_PREFIX/sherpa305/run/diag_tag/`, copies the cards there, and builds `hepmc3ToRoot` against
the system ROOT.

## Run

```sh
SHERPA3/LEP1_qqbar_ISR/run_production.sh                                       # standard isr0 and isr1, 20 at a time
for J in $(seq 1 10); do echo $J; done | VARIANT=keepall xargs -P 10 -I{} SHERPA3/LEP1_qqbar_ISR/run_shard.sh 1 {}
```
`run_shard.sh S J` uses seed `J` and writes `$MCF_PREFIX/sherpa305/qqbar/sherpa305_[keepall_]isr${S}_$((J-1)).root`;
its work directory `$MCF_PREFIX/sherpa305/run/prod_[keepall_]isr${S}_job$J` is emptied first, so Sherpa integrates
before generating. `OUTDIR` and `NEVENTS` override the output directory and the events per shard.

## ISR-on keep-all variant (the sample used for the C_ISR comparison)

With YFS ISR on, 2.49% of the events fail Sherpa's beam-blob momentum check (`Remnant_Handler::CheckBeamBreakup`,
tolerance 1e-6 x E_beam) and are replaced by new events. The rejection is not uniform in thrust: on the
production sample, dropping these events changes the normalized tau shape by +0.65 +- 0.03% in the first bin of the
analysis `tau_p30` binning (tau < 0.014), +0.35% and +0.09% in the next two, and -0.04% to -0.17% above.

The keep-all variant keeps these events and lists them. `keepall_beamblob_tag.patch` changes only
`REMNANTS/Main/Remnant_Handler.C`: a failed check no longer returns a new event but prints
`BEAMBLOB_FAIL <0-based event index>`. `setup.sh` builds it as a separate library (patch, `make Remnants` in the build tree, copy the library out, restore the
source and rebuild), and `run_shard.sh` with `VARIANT=keepall` preloads it, leaving the installed Sherpa unmodified
(the installed libraries carry an RPATH, so `LD_LIBRARY_PATH` cannot override them).
Output: `sherpa305_keepall_isr1_$((J-1)).root` and `tags_keepall_isr1_$((J-1)).txt` (the tagged event indices; in the
production 124434 lines, 124428 distinct events). The C_ISR comparison uses the standard ISR-off sample (no event fails
the check with ISR off) and the keep-all ISR-on sample.

Event record: per beam, Sherpa 3 merges the YFS photons into one final-state photon and keeps the individual photons
with status 3, so an ISR photon count must use either the merged photons or the status-3 ones, not both.

## Verification (2026-10-16)

- Fresh build from `setup.sh` into an empty `MCF_PREFIX`; `run_shard.sh` with `NEVENTS=200` for isr0, isr1 and
  keep-all isr1, seed 1: all 30 branches identical to shard 0 of the archived samples (`y` including its NaN entries),
  and the same 8 tagged events.

Checks against the production install:
- The patch applied to the 3.0.5 tarball source and built with `make Remnants` in the original build tree gives a
  library byte-identical to the one used for the production (sha256 `84ef082560c6011cc791355a1adfcd72c31926c8ba9551fc05fe5bdfcf7aa18b`).
- `hepmc3ToRoot` against the Sherpa 2.2.6 `hepmcToRoot`, on Sherpa 2.2.6 events (both converters) and on Sherpa 3
  events (native HepMC3 through `hepmc3ToRoot`, the same events written as HepMC2 through `hepmcToRoot`): event-level
  branches identical; particle records and mother/daughter links identical once particle ordering is ignored.
- ISR off: no event fails the beam-blob check (0 `MakeBeamBlobs failed` messages in the 10 production logs).
