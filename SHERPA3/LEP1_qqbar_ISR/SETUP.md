# Sherpa 3.0.5 (YFS ISR): LEP1 qqbar, ISR off / on

Replaces Sherpa 2.2.6's collinear electron structure function (`SHERPA2/LEP1_qqbar_ISR`) by YFS soft-photon
resummation of the ISR. Source: Sherpa 3.0.5 from gitlab.com/sherpa-team/sherpa (`common/sources.txt`). Install layout
and prerequisites: see the top-level `README.md`.

Cards: `Run_isr0.yaml`, `Run_isr1.yaml`. ISR off: `YFS: MODE: Off`; ISR on: `YFS: MODE: ISR`. Both have
`PDF_LIBRARY: None` and massive electrons (YFS needs them). Otherwise they match the Sherpa 2.2.6 cards: beam energy
45.594 GeV (sqrt(s) = 91.188 GeV), `ALPHAS(MZ): 0.1188`, process `11 -11 -> 93 93` at EW order 2. Output is native
HepMC3 (`HEPMC3_IO_TYPE: 0`), because the HepMC2 output contains `-nan` values on which the HepMC2 reader silently
stops. `hepmc3ToRoot.cc` is the HepMC3 port of `common/hepmcToRoot.cc`, writing the same `tgenBefore` tree.

## Set up

```sh
export MCF_PREFIX=<install root>
common/setup_hepmc3.sh                   # once
SHERPA3/LEP1_qqbar_ISR/setup.sh          # -> $MCF_PREFIX/sherpa305 and $MCF_PREFIX/sherpa305/run
```
`setup.sh` also builds the keep-all library (below) and `hepmc3ToRoot`. Its cmake step downloads libzip v1.9.2 from
GitHub.

## Run

```sh
SHERPA3/LEP1_qqbar_ISR/run_production.sh                                       # standard isr0 and isr1, 20 at a time
for J in $(seq 1 10); do echo $J; done | VARIANT=keepall xargs -P 10 -I{} SHERPA3/LEP1_qqbar_ISR/run_shard.sh 1 {}
```
Seeds, work directories and overrides: see the header of `run_shard.sh`.

## ISR-on keep-all variant

With YFS ISR on, about 2.5% of the events fail Sherpa's beam-blob momentum check
(`Remnant_Handler::CheckBeamBreakup`, tolerance 1e-6 x E_beam) and are replaced by new events. The rejection is not
uniform in thrust, so the standard ISR-on sample is biased. With ISR off no event fails the check.

The keep-all variant keeps these events and lists them. `keepall_beamblob_tag.patch` changes only
`REMNANTS/Main/Remnant_Handler.C`: a failed check no longer returns a new event but prints
`BEAMBLOB_FAIL <0-based event index>`. `setup.sh` builds it as a separate library in
`$MCF_PREFIX/sherpa305/run/diag_tag/`, and `run_shard.sh` with `VARIANT=keepall` preloads it, leaving the installed
Sherpa unmodified (the installed libraries carry an RPATH, so `LD_LIBRARY_PATH` cannot override them). Output:
`sherpa305_keepall_isr1_$((J-1)).root` and `tags_keepall_isr1_$((J-1)).txt` (the tagged event indices; an event can
be tagged more than once: the production has 124434 lines for 124428 distinct events).

Event record: per beam, Sherpa 3 merges the YFS photons into one final-state photon and keeps the individual photons
with status 3, so an ISR photon count must use either the merged photons or the status-3 ones, not both.

## Reference values

To check a new installation, run 1000 events of shard 0 and compare the output of `common/summarize.C` with the lines
below. They equal the first 1000 events of the production shards 0, so a matching installation reproduces the
production.
```sh
OUTDIR=$PWD/ref NEVENTS=1000 SHERPA3/LEP1_qqbar_ISR/run_shard.sh 0 1    # and 1 1, and VARIANT=keepall ... 1 1
root -l -b -q 'common/summarize.C("ref/sherpa305_isr0_0.root")'
```
```
sherpa305_isr0_0          events 1000  thrust(event 0) 0.931512  <thrust> 0.931400  <nParticle> 86.8060  <sum isCharged> 37.3110
sherpa305_isr1_0          events 1000  thrust(event 0) 0.978924  <thrust> 0.933564  <nParticle> 89.5670  <sum isCharged> 37.4170
sherpa305_keepall_isr1_0  events 1000  thrust(event 0) 0.978924  <thrust> 0.933456  <nParticle> 89.1270  <sum isCharged> 37.2370
```
