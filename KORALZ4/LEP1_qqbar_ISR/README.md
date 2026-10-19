# KORALZ 4.04 (ISR) + PYTHIA 8.317 (FSR + hadronization): LEP1 qqbar, ISR off / on

Matched to the KKMCee setup (`KKMCEE5/LEP1_qqbar_ISR`) and hadronized by the same `hadronizeKKMC`. Source: KORALZ
4.04, CPC Program Library ACBK_v3_0 on Mendeley Data (`acbk_v3_0.tar.gz` in `common/sources.txt`). Install layout and
prerequisites: see the top-level `README.md`.

`patches/0001-0006` are all our changes to the CPC tarball, one per change (see each patch's message). Two change the
events: 0002 sets alpha_s(MZ) in the DIZET interface from 0.125 to 0.1202, the value KKMCee feeds DIZET, and 0004
fixes a PHOTOS overrun that made every KORALZ run identical. The others add the gfortran build, the production
driver, the `MCF_PREFIX` paths, and a nonzero exit status when a shard fails.

Settings (hard-coded in `MainKoralzHepMC.f`): sqrt(s) = 91.1876 GeV, quark mode `ITFIN=500+q`, inputs matched
to the KKMCee cards and defaults (MZ, mH = 125.1, mt = 173, DIZET EW with `KEYGSW=4`, `KEYWLB=1`, constituent quark
masses d,u,s,c,b = 0.083, 0.100, 0.215, 1.5, 4.7 GeV, vvmin = 1e-5, vvmax = 0.99, e- along +z). ISR off: `KEYRAD=0`;
ISR on: `KEYRAD=12` (YFS3, ISR only, `KEYYFS=1000001`).

## Files

| File | What it is |
|---|---|
| `setup.sh` | unpacks the CPC tarball, applies the patches, builds KORALZ and the production driver |
| `patches/0001-0006` | all our changes to KORALZ 4.04 (below) |

The patches create `$MCF_PREFIX/koralz/ProdRun/`: `MainKoralzHepMC.f` (the driver, with all settings),
`hepmcWriter.cc`, `run_shard.sh`, `run_production.sh` and `pilot/sigma_nb.txt`.

## Set up

```sh
export MCF_PREFIX=<install root>
# after common/setup_hepmc3.sh and KKMCEE5/LEP1_qqbar_ISR/setup.sh
KORALZ4/LEP1_qqbar_ISR/setup.sh          # -> $MCF_PREFIX/koralz
```

## Run

```sh
$MCF_PREFIX/koralz/ProdRun/run_production.sh     # 20 shards, MAXPROC (default 20) at a time
```
KORALZ makes one flavour per run, so each shard is 5 runs (d,u,s,c,b) with events in proportion to the pilot cross
sections in `pilot/sigma_nb.txt`, `hadd`-ed in that order. Seeds, work directories and overrides: see
`$MCF_PREFIX/koralz/ProdRun/run_shard.sh`.

Known difference: `hadronizeKKMC` does not set a PYTHIA seed, so every flavour part hadronizes with PYTHIA's default
seed (19780503). This is what was run.

## Reference values

To check a new installation, run 1000 events of shard 0 and compare the output of `common/summarize.C` with the lines
below. `run_shard.sh` splits the 1000 events over the five flavours by the pilot cross sections, so these are not a
prefix of the 500k production shard; they come from a fresh build whose d-quark events match the production.
```sh
OUTDIR=$PWD/ref NEVENTS=1000 WORKROOT=$PWD/ref/work $MCF_PREFIX/koralz/ProdRun/run_shard.sh 0 0    # and 1 0
root -l -b -q 'common/summarize.C("ref/koralz_isr0_0.root")'
```
```
koralz_isr0_0             events 1000  thrust(event 0) 0.886846  <thrust> 0.928496  <nParticle> 110.9610  <sum isCharged> 38.3640
koralz_isr1_0             events 1000  thrust(event 0) 0.876965  <thrust> 0.930674  <nParticle> 111.2270  <sum isCharged> 37.8630
```
