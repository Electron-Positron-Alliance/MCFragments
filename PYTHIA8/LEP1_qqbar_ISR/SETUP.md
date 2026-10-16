# PYTHIA 8.317: LEP1 qqbar, ISR off / on (simple shower and Vincia)

All settings are hard-coded in `main304.cc` (there is no .cmnd). Install layout and prerequisites: see the top-level
`README.md`.

ISR on = `PDF:lepton = on` (with the default `PartonLevel:ISR = on`); ISR off = `PartonLevel:ISR = off` +
`PDF:lepton = off`. `PDF:lepton` is the switch that matters: the PYTHIA manual says that with it off "the colliding
leptons carry the full beam energy".

Vincia has no separate card: `-s 2` sets `PartonShowers:Model = 2` in `main304.cc`, and the archived Vincia logs show
that this is the only setting that differs from the default-shower samples (Vincia itself switches on
`TimeShower:interleaveResDec`).

## Set up

```sh
export MCF_PREFIX=<install root>
common/setup_root.sh                    # ROOT 6.36.04, once
PYTHIA8/LEP1_qqbar_ISR/setup.sh         # -> $MCF_PREFIX/pythia8317, examples/main304
```

## Run

```sh
PYTHIA8/LEP1_qqbar_ISR/run.sh 10 1 0 500000 <out>   # default shower, ISR off
PYTHIA8/LEP1_qqbar_ISR/run.sh 10 1 1 500000 <out>   # default shower, ISR on
PYTHIA8/LEP1_qqbar_ISR/run.sh 10 2 0 500000 <out>   # Vincia, ISR off
PYTHIA8/LEP1_qqbar_ISR/run.sh 10 2 1 500000 <out>   # Vincia, ISR on
```
Arguments, seeds and output names: see `run.sh`.

## Reference values

To check a new installation, run 1000 events of shard 0 and compare the output of `common/summarize.C` with the lines
below. They equal the first 1000 events of the production shards 0, so a matching installation reproduces the
production.
```sh
PYTHIA8/LEP1_qqbar_ISR/run.sh 1 1 0 1000 ref    # and 1 1 1, 1 2 0, 1 2 1
root -l -b -q 'common/summarize.C("ref/pythia8317_isr0_0.root")'
```
```
pythia8317_isr0_0         events 1000  thrust(event 0) 0.831696  <thrust> 0.935137  <nParticle> 111.7550  <sum isCharged> 40.7800
pythia8317_isr1_0         events 1000  thrust(event 0) 0.906056  <thrust> 0.932067  <nParticle> 119.3880  <sum isCharged> 43.0190
pythia8317_vincia_isr0_0  events 1000  thrust(event 0) 0.979765  <thrust> 0.932802  <nParticle> 105.8480  <sum isCharged> 39.5070
pythia8317_vincia_isr1_0  events 1000  thrust(event 0) 0.965986  <thrust> 0.930946  <nParticle> 108.2570  <sum isCharged> 39.9280
```
