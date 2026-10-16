# PYTHIA 8.317: LEP1 qqbar, ISR off / on (simple shower and Vincia)

Platform and shared dependencies: see the top-level `README.md`.

Files: `main304.cc` (all settings are hard-coded here; there is no .cmnd), `run.sh`, `Makefile` (the PYTHIA
`examples/Makefile` with `main304` added to the ROOT rule), `Makefile.inc.configured` (the `Makefile.inc` written by
`./configure`).

Source: PYTHIA 8.317, `pythia8317.tgz` from pythia.org (sha256 not recorded; the tarball was not kept).

```sh
source <ROOT 6.36.04>/bin/thisroot.sh          # required: the Makefile calls root-config from PATH
cd pythia8317 && ./configure --with-root=<ROOT 6.36.04>   # inferred from Makefile.inc.configured (ROOT is the only option enabled)
make -j
cp main304.cc run.sh Makefile examples/ && cd examples && make main304
export PYTHIA8DATA=<pythia8317>/share/Pythia8/xmldoc
./run.sh 10 1 0 500000 <out>   # default shower, ISR off -> pythia8317_isr0_{0..9}.root,        seeds 200001..200010
./run.sh 10 1 1 500000 <out>   # default shower, ISR on  -> pythia8317_isr1_{0..9}.root,        seeds 100001..100010
./run.sh 10 2 0 500000 <out>   # Vincia,         ISR off -> pythia8317_vincia_isr0_{0..9}.root, seeds 400001..400010
./run.sh 10 2 1 500000 <out>   # Vincia,         ISR on  -> pythia8317_vincia_isr1_{0..9}.root, seeds 300001..300010
```

ISR on = `PDF:lepton = on` (with the default `PartonLevel:ISR = on`); ISR off = `PartonLevel:ISR = off` +
`PDF:lepton = off`. `PDF:lepton` is the switch that matters: the PYTHIA manual says that with it off "the colliding
leptons carry the full beam energy".

Vincia has no separate card: `-s 2` sets `PartonShowers:Model = 2` in `main304.cc`, and the archived Vincia logs show
that this is the only setting that differs from the default-shower samples (Vincia itself switches on
`TimeShower:interleaveResDec`). Dire (`-s 3`) was removed from public PYTHIA after 8.310 and was not used.

The same `main304.cc` ntuple layout (`tgenBefore`) is written by every generator in `*/LEP1_qqbar_ISR`.

## Verification (2026-10-08)

Rebuilt `main304` from these files; 300 events of isr0 seed 200001 and of Vincia isr1 seed 300001 give ntuples
identical to the archived shards (29 branches).
