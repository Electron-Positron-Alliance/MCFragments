# PYTHIA 8.317: LEP1 qqbar, ISR off / on (simple shower and Vincia)

Files: `main304.cc` (all settings are hard-coded here; there is no .cmnd), `setup.sh`, `run.sh`.
Install layout and prerequisites: see the top-level `README.md`.

## Set up

```sh
export MCF_PREFIX=<install root>
common/setup_root.sh                    # ROOT 6.36.04, once
PYTHIA8/LEP1_qqbar_ISR/setup.sh         # -> $MCF_PREFIX/pythia8317, examples/main304
```
`setup.sh` downloads `pythia8317.tgz` (pythia.org, sha256 in `common/sources.txt`), runs
`./configure --with-root=$MCF_PREFIX/root` (ROOT is the only option enabled), `make`, adds `main304` to the ROOT rule
of `examples/Makefile` and builds it.

## Run

```sh
PYTHIA8/LEP1_qqbar_ISR/run.sh 10 1 0 500000 <out>   # default shower, ISR off -> pythia8317_isr0_{0..9}.root,        seeds 200001..200010
PYTHIA8/LEP1_qqbar_ISR/run.sh 10 1 1 500000 <out>   # default shower, ISR on  -> pythia8317_isr1_{0..9}.root,        seeds 100001..100010
PYTHIA8/LEP1_qqbar_ISR/run.sh 10 2 0 500000 <out>   # Vincia,         ISR off -> pythia8317_vincia_isr0_{0..9}.root, seeds 400001..400010
PYTHIA8/LEP1_qqbar_ISR/run.sh 10 2 1 500000 <out>   # Vincia,         ISR on  -> pythia8317_vincia_isr1_{0..9}.root, seeds 300001..300010
```
`MAXPAR` caps the number of concurrent shards (default: all).

ISR on = `PDF:lepton = on` (with the default `PartonLevel:ISR = on`); ISR off = `PartonLevel:ISR = off` +
`PDF:lepton = off`. `PDF:lepton` is the switch that matters: the PYTHIA manual says that with it off "the colliding
leptons carry the full beam energy".

Vincia has no separate card: `-s 2` sets `PartonShowers:Model = 2` in `main304.cc`, and the archived Vincia logs show
that this is the only setting that differs from the default-shower samples (Vincia itself switches on
`TimeShower:interleaveResDec`). Dire (`-s 3`) was removed from public PYTHIA after 8.310 and was not used.

The `tgenBefore` ntuple layout of `main304.cc` is written by every generator in `*/LEP1_qqbar_ISR`.

## Verification (2026-10-16)

Fresh build from `setup.sh` into an empty `MCF_PREFIX`; `run.sh` for 300 events of isr0 seed 200001 and of Vincia isr1
seed 300001: ntuples identical to the archived shards 0 (29 branches).
