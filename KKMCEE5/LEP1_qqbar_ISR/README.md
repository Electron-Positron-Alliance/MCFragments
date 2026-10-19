# KKMCee 5 (ISR) + PYTHIA 8.317 (FSR + hadronization): LEP1 qqbar, ISR off / on

KKMCee at git commit `bf3cce7f4326c34de81a39daf30fadbb6836bd94` of github.com/KrakowHEPSoft/KKMCee, unmodified.
Install layout and prerequisites: see the top-level `README.md`.

The two production cards `prodrun/workQQ2_isr{0,1}/pro.input` differ only in `KeyISR = xpar(20)` (0 / 1). FSR in
KKMCee is off (`xpar(21)=0`); PYTHIA does it. Events are unweighted (`xpar(10)=0`). All other parameters are KKMCee's
`SRCee/KKMCee_defaults`. `prodrun/workQQ2_dizet/pro.input` is the card from which `setup.sh` tabulates the 5-quark
DIZET electroweak table that every shard reads. `prodrun/hadronizeKKMC.cc` does the PYTHIA 8.317 FSR and
hadronization (default Monash tune) of the KKMCee and KORALZ events.

## Files

| File | What it is |
|---|---|
| `setup.sh` | clones and builds KKMCee, builds `MainHepMC` and `hadronizeKKMC`, makes the DIZET table |
| `prodrun/workQQ2_isr0/pro.input`, `prodrun/workQQ2_isr1/pro.input` | the production cards (ISR off / on) |
| `prodrun/workQQ2_dizet/pro.input` | the card for the DIZET electroweak table |
| `prodrun/MainHepMC.cxx` | KKMCee -> HepMC3 driver (seed from `KKMC_SEED`) |
| `prodrun/hadronizeKKMC.cc` | PYTHIA 8.317 FSR + hadronization of the KKMCee and KORALZ events, writes the ntuple |
| `prodrun/run_shard.sh`, `prodrun/run_production.sh` | one shard / all 20 shards |
| `prodrun/setup_kkmc_env.sh` | runtime environment, sourced by the run scripts |

`setup.sh` copies `prodrun/` into `$MCF_PREFIX/kkmcee/ProdRun/`, where the run scripts are used.

## Set up

```sh
export MCF_PREFIX=<install root>
common/setup_root.sh && common/setup_hepmc3.sh && common/setup_photospp.sh
PYTHIA8/LEP1_qqbar_ISR/setup.sh          # hadronizeKKMC links PYTHIA 8.317
KKMCEE5/LEP1_qqbar_ISR/setup.sh          # -> $MCF_PREFIX/kkmcee
```
`setup.sh` stops unless the DIZET table it makes is byte-identical to the production table.

## Run

```sh
export MCF_PREFIX=<install root>
$MCF_PREFIX/kkmcee/ProdRun/run_production.sh     # 20 shards, MAXPROC (default 20) at a time
```
Seeds, work directories and overrides: see `prodrun/run_shard.sh`.

Known difference: `hadronizeKKMC` does not set a PYTHIA seed, so every KKMCee shard (and every KORALZ shard and flavour
part) hadronizes with PYTHIA's default seed (19780503). This is what was run.

## Reference values

To check a new installation, run 1000 events of shard 0 and compare the output of `common/summarize.C` with the lines
below. They equal the first 1000 events of the production shards 0, so a matching installation reproduces the
production.
```sh
OUTDIR=$PWD/ref NEVENTS=1000 $MCF_PREFIX/kkmcee/ProdRun/run_shard.sh 0 0    # and 1 0
root -l -b -q 'common/summarize.C("ref/kkmcee_isr0_0.root")'
```
```
kkmcee_isr0_0             events 1000  thrust(event 0) 0.887663  <thrust> 0.932869  <nParticle> 109.7500  <sum isCharged> 37.6390
kkmcee_isr1_0             events 1000  thrust(event 0) 0.875025  <thrust> 0.928410  <nParticle> 111.0210  <sum isCharged> 37.6980
```
