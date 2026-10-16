# KORALZ 4.04 (ISR) + PYTHIA 8.317 (FSR + hadronization): LEP1 qqbar, ISR off / on

A C_ISR cross-check, drawn beside the generators but not used in the correction or its systematic. Matched to the
KKMCee setup (`KKMCEE5/LEP1_qqbar_ISR`) and hadronized by the same `hadronizeKKMC`. Install layout and prerequisites:
see the top-level `README.md`.

Files: `setup.sh` and `patches/0001-0005`, the full set of changes on top of the CPC tarball:
1. gfortran build of the libraries and demos (`build_gfortran.sh`, `validate_numdiff.py`);
2. DIZET 5.0 interface: alpha_s(MZ) 0.125 -> 0.1202, the value KKMCee feeds DIZET;
3. the production driver in `ProdRun/`: `MainKoralzHepMC.f` (all the settings, as hard-coded NPR/XPR),
   `hepmcWriter.cc`, `Makefile`, `run_shard.sh`, `run_production.sh`, and `pilot/` (cross sections that set the
   per-flavour split; `run_shard.sh` reads them);
4. the PHOTOS PHOCIN overrun fix (it made every KORALZ run identical) and the YFS3 MARRAN seeding;
5. the install root from `MCF_PREFIX` instead of absolute paths.

Settings (`MainKoralzHepMC.f`): sqrt(s) = 91.1876 GeV, quark mode `ITFIN=500+q`, inputs matched to the KKMCee cards
and defaults (MZ, mH = 125.1, mt = 173, DIZET EW with `KEYGSW=4`, `KEYWLB=1`, constituent quark masses
d,u,s,c,b = 0.083, 0.100, 0.215, 1.5, 4.7 GeV, vvmin = 1e-5, vvmax = 0.99, e- along +z). ISR off: `KEYRAD=0`;
ISR on: `KEYRAD=12` (YFS3, ISR only, `KEYYFS=1000001`).

Source: KORALZ 4.04, CPC Program Library ACBK_v3_0 on Mendeley Data (`acbk_v3_0.tar.gz`, URL and sha256 in
`common/sources.txt`).

## Set up

```sh
export MCF_PREFIX=<install root>
# after common/setup_hepmc3.sh and KKMCEE5/LEP1_qqbar_ISR/setup.sh
KORALZ4/LEP1_qqbar_ISR/setup.sh          # -> $MCF_PREFIX/koralz
```
`setup.sh` unpacks the tarball into a new git repository, `git am`s the patches, runs `build_gfortran.sh` (add
`--validate` by hand to compare the demos with the 1999 references) and builds `ProdRun/MainKoralzHepMC`.

## Run

```sh
$MCF_PREFIX/koralz/ProdRun/run_production.sh     # 20 shards, MAXPROC (default 20) at a time
```
One run per quark flavour: flavour `q` of shard `I`, state `S` uses seed `1000000 + 100000*S + 10*I + q`, and the 5
parts are `hadd`-ed in order d,u,s,c,b into `$MCF_PREFIX/koralz/qqbar/koralz_isr${S}_${I}.root`. Events per flavour
for a 500k shard, from `pilot/`: ISR off 110633/85895/110656/85772/107044, ISR on 110590/85906/110628/85884/106992.
`OUTDIR`, `NEVENTS` and `WORKROOT` override the output directory, the events per shard and the work-directory root of
`run_shard.sh S I`.

Known difference: `hadronizeKKMC` does not set a PYTHIA seed, so every flavour part hadronizes with PYTHIA's default
seed (19780503). This is what was run.

## Reference values

To check a new installation, run 1000 events of shard 0 and compare the output of `common/summarize.C` with the lines
below (fresh build, 2026-10-16). `run_shard.sh` splits the 1000 events over the five flavours by the pilot cross
sections, so these are not a prefix of the 500k production shard; they come from the fresh build, whose q=d events match
the production (Verification).
```sh
OUTDIR=$PWD/ref NEVENTS=1000 WORKROOT=$PWD/ref/work $MCF_PREFIX/koralz/ProdRun/run_shard.sh 0 0    # and 1 0
root -l -b -q 'common/summarize.C("ref/koralz_isr0_0.root")'
```
```
koralz_isr0_0  events 1000  thrust(event 0) 0.886846  <thrust> 0.928496  <nParticle> 110.9610  <sum isCharged> 38.3640
koralz_isr1_0  events 1000  thrust(event 0) 0.876965  <thrust> 0.930674  <nParticle> 111.2270  <sum isCharged> 37.8630
```

## Verification (2026-10-16)

Fresh build from `setup.sh` into an empty `MCF_PREFIX`. `MainKoralzHepMC 300 q1.hepmc3 1 1 1100001` (q=d, isr1,
seed 1100001) writes a HepMC3 file byte-identical to the production binary's, and after `hadronizeKKMC` an ntuple
identical to the first 300 events of the archived `koralz_isr1_0.root` (30 branches). `run_shard.sh 1 0` with
`NEVENTS=300` gives the same first 68 (d-quark) events.
