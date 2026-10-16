# Sherpa 2.2.6: LEP1 qqbar, ISR off / on

In the C_ISR systematic envelope. Install layout and prerequisites: see the top-level `README.md`.

Files: `Run_isr0.dat`, `Run_isr1.dat` (the cards), `setup.sh`, `run_production.sh`, `env.sh`, `hepmcToRoot.cc` +
`Makefile` (HepMC2 -> `tgenBefore` ntuple; the same converter as `HERWIG7/LEP1_qqbar_ISR`), and `patches/` (GCC 11
compile fix).

ISR off: `PDF_LIBRARY None`; ISR on: `BUNCH_1 11; BUNCH_2 -11`, i.e. the electron structure function (leading log,
collinear: one photon per beam with zero pT). YFS (Photons++) in Sherpa 2.2.6 acts on decays only, so it does not add
ISR here. sqrt(s) = 91.188 GeV.

## Set up

```sh
export MCF_PREFIX=<install root>
SHERPA2/LEP1_qqbar_ISR/setup.sh          # -> $MCF_PREFIX/sherpa226 and $MCF_PREFIX/sherpa226/run
```
`setup.sh` downloads (URLs and sha256 in `common/sources.txt`) and installs into `$MCF_PREFIX/sherpa226`:

| Package | Version | Build |
|---|---|---|
| FastJet | 3.3.4 | `configure --enable-shared` |
| HepMC | 2.06.11 | `configure --with-momentum=GEV --with-length=MM` |
| LHAPDF | 6.3.0 | `configure --disable-python`; PDF sets `MMHT2014lo68cl`, `MMHT2014nlo68cl` |
| Sherpa | 2.2.6 | GCC 11 patch; `configure --enable-hepmc2 --enable-lhapdf` (= the prefix) `--enable-gzip=no --enable-mpi=no` |

It then copies the cards and the converter into `$MCF_PREFIX/sherpa226/run` and builds `hepmcToRoot` there (system
ROOT, `root-config` from PATH). Sherpa needs the system SQLite (`sqlite-devel`).

## Run

```sh
SHERPA2/LEP1_qqbar_ISR/run_production.sh     # 20 jobs, MAXPAR (default 20) at a time
```
In `$MCF_PREFIX/sherpa226/run`, job `j` (1-10) = seed `j` = shard `j-1`: an emptied directory `sherpa_isr${S}_job$j`
with the card as `Run.dat`, `Sherpa -e 500000 -R $j`, then `hepmcToRoot` on `events.hepmc2g` (kept) ->
`sherpa226_isr${S}_$((j-1)).root`. `NEVENTS`, `SEEDS` and `STATES` select fewer events, seeds or states.

Every job must start from an empty directory, so that Sherpa integrates before generating. A directory that already
holds `Results.db` skips the integration and gives a different event sequence; `run_production.sh` therefore empties
each job directory first.

Known differences from the archived ntuples:
- Shards 0-4 (both ISR states) were converted before the 2026-03-21 16:27 rebuild of `hepmcToRoot`, by a version
  whose source was not kept. In those shards `sqrt_sHat` and `mHat` are 91.188 for every event, while this converter
  writes the hadronic mass when there is no Z in the record. ISR-on shards 5-9 already use this converter's definition.
  Per-particle `mass` (up to 4e-5 GeV on near-massless particles) and `y` of beam-collinear particles (|y| ~ 12) also
  differ slightly. The analysis reads `mass` but not `sqrt_sHat`, `mHat` or `y`.
- `hepmcToRoot.cc` was edited on 2026-03-27, after the ntuples were made: it leaves the `pwflag` branch unfilled, while
  the archived ntuples have it filled. The analysis derives `pwflag` from `pdgid` itself.

## Verification (2026-10-16)

Fresh build from `setup.sh` into an empty `MCF_PREFIX`; `run_production.sh` with `NEVENTS=100` for isr0 seed 1 and
isr1 seeds 1 and 5, against the archived shards 0, 0 and 4: the same events (identical particle multiplicities,
momenta, energies, PDG ids, status codes and relations). The only differences are the converter-version ones listed
above: `sqrt_sHat` and `mHat`, `mass` (at most 3.8e-5 GeV), `y` of 5 beam-collinear particles, and `pwflag`.
