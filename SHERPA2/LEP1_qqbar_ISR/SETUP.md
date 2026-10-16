# Sherpa 2.2.6: LEP1 qqbar, ISR off / on

In the C_ISR systematic envelope. Platform: see the top-level `README.md`.

Files: `Run_isr0.dat`, `Run_isr1.dat`, `run_isr.sh`, `env.sh`, `hepmcToRoot.cc` + `Makefile` (HepMC2 -> `tgenBefore`
ntuple; the same converter as `HERWIG7/LEP1_qqbar_ISR`).

ISR off: `PDF_LIBRARY None`; ISR on: `BUNCH_1 11; BUNCH_2 -11`, i.e. the electron structure function (leading log,
collinear: one photon per beam with zero pT). YFS (Photons++) in Sherpa 2.2.6 acts on decays only, so it does not add
ISR here. sqrt(s) = 91.188 GeV.

| Package | Version | File | sha256 |
|---|---|---|---|
| Sherpa | 2.2.6 | `SHERPA-MC-2.2.6.tar.gz` | `f114e68ed610ff80b772d5ee50fb1cd129d0219f38f0825cbb80ca1bfe9c4fb1` |
| HepMC2 | 2.06.11 | `hepmc2.06.11.tgz` | `86b66ea0278f803cde5774de8bd187dd42c870367f1cbf6cdaec8dc7cf6afc10` |
| LHAPDF | 6.3.0 | `LHAPDF-6.3.0.tar.gz` | `ed4d8772b7e6be26d1a7682a13c87338d67821847aa1640d78d67d2cef8b9b5d` |
| FastJet | 3.3.4 | `fastjet-3.3.4.tar.gz` | `432b51401e1335697c9248519ce3737809808fc1f6d1644bfae948716dddfc03` |

LHAPDF sets installed: `MMHT2014lo68cl`, `MMHT2014nlo68cl`.

Build (prefix `P=/home/badea/code/sherpa226`):
```sh
<fastjet-3.3.4>/configure --prefix=$P --enable-shared
<HepMC-2.06.11>/configure --prefix=$P --with-momentum=GEV --with-length=MM
<LHAPDF-6.3.0>/configure --prefix=$P --disable-python
<SHERPA-MC-2.2.6>/configure --prefix=$P --enable-hepmc2=$P --enable-lhapdf=$P --enable-gzip=no --enable-mpi=no
```

Run, job `j` = seed `j` = shard `j-1`, each in its own **empty** directory with the card copied to `Run.dat`:
```sh
source env.sh
mkdir sherpa_isr${S}_job$j && cp Run_isr$S.dat sherpa_isr${S}_job$j/Run.dat
(cd sherpa_isr${S}_job$j && Sherpa -e 500000 -R $j)
make && ./hepmcToRoot -f sherpa_isr${S}_job$j/events.hepmc2g -o sherpa226_isr${S}_$((j-1)).root
```
Every job must start from an empty directory, so that Sherpa integrates before generating. A directory that already
holds `Results.db` skips the integration and gives a different event sequence.

Known differences from the archived ntuples:
- Shards 0-4 (both ISR states) were converted before the 2026-03-21 16:27 rebuild of `hepmcToRoot`, by a version
  whose source was not kept. In those shards `sqrt_sHat` and `mHat` are 91.188 for every event, while this converter
  writes the hadronic mass when there is no Z in the record. ISR-on shards 5-9 already use this converter's definition.
  Per-particle `mass` (up to 4e-5 GeV on near-massless particles) and `y` of beam-collinear particles (|y| ~ 12) also
  differ slightly. The analysis reads `mass` but not `sqrt_sHat`, `mHat` or `y`.
- `hepmcToRoot.cc` was edited on 2026-03-27, after the ntuples were made: it leaves the `pwflag` branch unfilled, while
  the archived ntuples have it filled. The analysis derives `pwflag` from `pdgid` itself.

## Verification (2026-10-08)

From empty directories, 100 events each of isr0 seed 1 and isr1 seeds 1 and 5 against ntuple shards 0, 0 and 4: all
branches identical except `sqrt_sHat`, `mHat`, `mass` and `y` (see above). isr1 seed 6 against the archived HepMC
file of job 6: same particles, momenta agreeing to ~1e-5 GeV (one particle 2 MeV).
