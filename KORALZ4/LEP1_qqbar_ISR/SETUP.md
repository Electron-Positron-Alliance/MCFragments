# KORALZ 4.04 (ISR) + PYTHIA 8.317 (FSR + hadronization): LEP1 qqbar, ISR off / on

A C_ISR cross-check, drawn beside the generators but not used in the correction or its systematic. Matched to the
KKMCee setup (`KKMCEE5/LEP1_qqbar_ISR`) and hadronized by the same `hadronizeKKMC`. Platform and shared dependencies:
see the top-level `README.md`.

Files:
- `patches/0001-0004`: the full set of changes on top of the CPC tarball: gfortran build, DIZET
  alpha_s(MZ) 0.125 -> 0.1202, the production driver, and the PHOTOS PHOCIN overrun fix.
- `prodrun/`: plain copies of the production files the patches create: `MainKoralzHepMC.f` (all the settings, as
  hard-coded NPR/XPR), `run_shard.sh`, `run_production.sh`, `Makefile`, `hepmcWriter.cc`, and `pilot/` (the cross
  sections that set the per-flavour split).

Source: KORALZ 4.04, CPC Program Library ACBK_v3_0, `acbk_v3_0.tar.gz`, sha256
`3489fe614647ed32a3f24c5e7796d2d518b6a146d4c8708cd182cdf3be14c112`.

```sh
mkdir koralz && cd koralz && tar xzf acbk_v3_0.tar.gz
git init && git add -A && git commit -m "KORALZ 4.04 CPC ACBK_v3_0"
git am <this folder>/patches/*.patch
sh build_gfortran.sh            # builds the libraries + demos (add --validate to check against the 1999 references)
cd ProdRun && make              # needs HepMC3 at /home/badea/code/local (HEPMC in Makefile)
./run_production.sh             # uses KKMCee's ProdRun/hadronizeKKMC and setup_kkmc_env.sh
```

ISR off: `KEYRAD=0`; ISR on: `KEYRAD=12` (YFS3, ISR only). One run per quark flavour; flavour `q` of shard `I`,
state `S` uses seed `1000000 + 100000*S + 10*I + q`, and the 5 parts are `hadd`-ed in order d,u,s,c,b.
Events per flavour, from `pilot/`: ISR off 110633/85895/110656/85772/107044, ISR on 110590/85906/110628/85884/106992.

Known difference: `hadronizeKKMC` does not set a PYTHIA seed, so every flavour part hadronizes with PYTHIA's default
seed (19780503). This is what was run.

## Verification (2026-10-08)

CPC tarball + these patches, rebuilt; 300 events of q=d, isr1, seed 1100001 give a HepMC file identical to the original
binary's and an identical ntuple.
