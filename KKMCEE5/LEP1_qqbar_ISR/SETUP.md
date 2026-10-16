# KKMCee 5 (ISR) + PYTHIA 8.317 (FSR + hadronization): LEP1 qqbar, ISR off / on

The C_ISR reference generator. Install layout and prerequisites: see the top-level `README.md`.

Files:
- `prodrun/workQQ2_isr0/pro.input`, `prodrun/workQQ2_isr1/pro.input`: the two production cards. They differ only in
  `KeyISR = xpar(20)` (0 / 1). FSR in KKMCee is off (`xpar(21)=0`); PYTHIA does it. Events are unweighted
  (`xpar(10)=0`). All other parameters are KKMCee's `SRCee/KKMCee_defaults`.
- `prodrun/workQQ2_dizet/pro.input`: the card `setup.sh` gives `DZface/TabMainC` to tabulate the 5-quark DIZET
  electroweak table every shard reads.
- `prodrun/MainHepMC.cxx`: KKMCee -> HepMC3, seed from `KKMC_SEED`.
- `prodrun/hadronizeKKMC.cc`: PYTHIA 8.317 FSR + hadronization of the KKMCee (and KORALZ) HepMC3 events, default
  Monash tune, writes the `tgenBefore` ntuple.
- `prodrun/run_shard.sh`, `prodrun/run_production.sh`, `prodrun/setup_kkmc_env.sh` (runtime environment).
- `setup.sh`.

## Set up

```sh
export MCF_PREFIX=<install root>
common/setup_root.sh && common/setup_hepmc3.sh && common/setup_photospp.sh
PYTHIA8/LEP1_qqbar_ISR/setup.sh          # hadronizeKKMC links PYTHIA 8.317
KKMCEE5/LEP1_qqbar_ISR/setup.sh          # -> $MCF_PREFIX/kkmcee
```
`setup.sh` clones github.com/KrakowHEPSoft/KKMCee at `bf3cce7f4326c34de81a39daf30fadbb6836bd94` (unmodified), links
`dizet -> dizet-6.45`, runs `autoreconf -f -i` and
`./configure CXXFLAGS="-std=c++17 -g -O2" --with-hepmc=$MCF_PREFIX/local --with-photos=$MCF_PREFIX/local/photos` with
ROOT 6.36.04 on PATH, and `make`. It then copies `prodrun/` into `ProdRun/`, builds `MainHepMC` (against ROOT 6.36.04)
and `hadronizeKKMC` (against the system ROOT 6.38.04), and tabulates `ProdRun/workQQ2_dizet/DIZET-table1`, stopping
unless its sha256 is the production table's (`28788f8f...25cdcf49`).

## Run

```sh
export MCF_PREFIX=<install root>
$MCF_PREFIX/kkmcee/ProdRun/run_production.sh     # 20 shards, MAXPROC (default 20) at a time
```
Shard `I` (0-9) of ISR state `S` runs in `ProdRun/prod2_isr${S}_${I}` with seed `1000000 + 100000*S + I + 1`:
`MainHepMC 500000`, then `hadronizeKKMC`, then the temporary HepMC3 file is deleted. Output:
`$MCF_PREFIX/kkmcee/qqbar_v2/kkmcee_isr${S}_${I}.root`. `OUTDIR` and `NEVENTS` override the output directory and
the events per shard of `run_shard.sh S I`.

Known difference: `hadronizeKKMC` does not set a PYTHIA seed, so every KKMCee shard (and every KORALZ shard and flavour
part) hadronizes with PYTHIA's default seed (19780503). This is what was run.

History: a first KKMCee production (v1, weighted events `xpar(10)=1` and a mu-only DIZET table) was the C_ISR reference
until 2026-10-02. It is superseded by this one and not included.

## Verification (2026-10-16)

Fresh build from `setup.sh` into an empty `MCF_PREFIX`: the DIZET table is byte-identical to the production table, and
`run_shard.sh` with `NEVENTS=300` gives shard 0 of both ISR states identical to the archived shards (30 branches).
