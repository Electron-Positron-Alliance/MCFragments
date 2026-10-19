# MCFragments
Contains the MC fragments utilized to generate simulations used by the EPA. 

## LEP1 e+e- -> qqbar with initial-state radiation on/off (`*/LEP1_qqbar_ISR/`)

Paired ISR-off (`isr0`) / ISR-on (`isr1`) samples of e+e- -> qqbar (5 flavours) at the Z pole, used for the ALEPH
thrust QED ISR correction C_ISR = (ISR off) / (ISR on). Each sample is 10 shards x 500k events per ISR state, written
as a `tgenBefore` ntuple with the branch layout of `PYTHIA8/LEP1_qqbar_ISR/main304.cc`.

ISR (initial-state radiation) here means QED photon emission from the incoming e+ and e-, which lowers the energy of
the hard collision. Within each pair only ISR is switched; final-state radiation stays at each generator's defaults
and is the same in both samples. In PYTHIA (also the FSR and hadronization step of KKMCee and KORALZ) this includes
photon splittings gamma -> l+l- in the final-state shower: `TimeShower:nGammaToLepton` keeps its default, 3 (e, mu,
tau).

| Generator | sqrt(s) [GeV] | ISR off / on | Folder |
|---|---|---|---|
| KKMCee 5 (ISR) + PYTHIA 8.317 (FSR + hadronization) | 91.1876 | `KeyISR` = `xpar(20)` 0 / 1 | `KKMCEE5/LEP1_qqbar_ISR` |
| KORALZ 4.04 (ISR) + the same PYTHIA 8.317 hadronizer | 91.1876 | `KEYRAD` 0 / 12 | `KORALZ4/LEP1_qqbar_ISR` |
| PYTHIA 8.317, simple shower | 91.1876 | `PDF:lepton`, `PartonLevel:ISR` off / on | `PYTHIA8/LEP1_qqbar_ISR` |
| PYTHIA 8.317, Vincia shower | 91.1876 | as above | `PYTHIA8/LEP1_qqbar_ISR` (`-s 2`) |
| Herwig 7.1.5 | 91.188 | `NoPDF` + `DoISR No` / `LeptonPDF` + `DoISR Yes` | `HERWIG7/LEP1_qqbar_ISR` |
| Sherpa 2.2.6 | 91.188 | `PDF_LIBRARY None` / `BUNCH_1 11; BUNCH_2 -11` | `SHERPA2/LEP1_qqbar_ISR` |
| Sherpa 3.0.5 | 91.188 | `YFS: MODE: Off` / `ISR` | `SHERPA3/LEP1_qqbar_ISR` |

The archived ALEPH 1994 PYTHIA 6.1 MC is official ALEPH MC and is not here.

Each folder has a `README.md` (files, how ISR is switched, set up, run, reference values) and the files that made the
samples.
Nothing large is stored here: the setup scripts download every upstream source and check its sha256
(`common/sources.txt`).

### Install layout

Everything installs under one root, `MCF_PREFIX` (an absolute path to any writable directory). Downloads go
to `$MCF_PREFIX/src`. Our production used `MCF_PREFIX=/home/badea/code`, except that ROOT 6.36.04 sat in
`/home/badea/root` rather than `$MCF_PREFIX/root`.

| Path | Contents | Made by |
|---|---|---|
| `$MCF_PREFIX/root` | ROOT 6.36.04 binary release | `common/setup_root.sh` |
| `$MCF_PREFIX/local` | HepMC3 3.2.5 | `common/setup_hepmc3.sh` |
| `$MCF_PREFIX/local/photos` | PHOTOS++ 3.64 | `common/setup_photospp.sh` (after HepMC3) |

No generator needs to be installed beforehand: each `setup.sh` downloads its generator and every library it needs
and builds them. Only the system packages under "Platform and prerequisites" must already be there. Set up
everything, in this order (each `setup.sh` starts from scratch in its own directory under `$MCF_PREFIX`):
```sh
export MCF_PREFIX=$HOME/mcf MCF_JOBS=8      # MCF_JOBS: parallel build jobs (default: all cores)
common/setup_root.sh && common/setup_hepmc3.sh && common/setup_photospp.sh   # ROOT 6.36.04, HepMC3, PHOTOS++
PYTHIA8/LEP1_qqbar_ISR/setup.sh             # builds PYTHIA 8.317 (with ROOT; no jet finder is used) and main304
KKMCEE5/LEP1_qqbar_ISR/setup.sh             # builds KKMCee and its hadronizer; uses the ROOT, HepMC3, PHOTOS++, PYTHIA above
KORALZ4/LEP1_qqbar_ISR/setup.sh             # builds KORALZ 4.04; uses HepMC3 and the KKMCee hadronizer
HERWIG7/LEP1_qqbar_ISR/setup.sh             # builds Herwig 7.1.5 and all its dependencies (Boost, CLHEP, FastJet, HepMC2, LHAPDF, ThePEG)
SHERPA2/LEP1_qqbar_ISR/setup.sh             # builds Sherpa 2.2.6 and all its dependencies
SHERPA3/LEP1_qqbar_ISR/setup.sh             # builds Sherpa 3.0.5; uses HepMC3
```
Each folder's `README.md` then gives the production command and reference values: `common/summarize.C` prints a
few numbers for a 1000-event check run, to compare with the lines listed there. A complete install of all generators
took 7.3 GB on the validation machine, 4.5 GB of it unpacked sources and build trees in `$MCF_PREFIX/src`.
HepMC3 is used by KKMCee, KORALZ and Sherpa 3; PHOTOS++ by KKMCee.

### Platform and prerequisites

RHEL 9.8 (x86_64), GCC/gfortran 11.5.0; other platforms are untested. System packages used: `gcc gcc-c++
gcc-gfortran make cmake autoconf automake libtool git curl tar bzip2 xz patch sqlite-devel gsl-devel zlib-devel`,
and ROOT 6.38.04 from EPEL (`dnf install root`; `root-6.38.04-5.el9` was used). Building Sherpa 3 also needs network
access, because its build fetches libzip v1.9.2 from GitHub.

Two ROOT installs are used, deliberately:
- ROOT 6.36.04 binary release (`$MCF_PREFIX/root`): `root-config` on PATH when building PYTHIA 8.317, KKMCee and
  `MainHepMC`.
- ROOT 6.38.04 system package (`/usr/lib64/root`, `/usr/bin/root-config`): used to build `hadronizeKKMC`, the
  Herwig/Sherpa 2 `hepmcToRoot` and the Sherpa 3 `hepmc3ToRoot`, and at runtime for KKMCee/KORALZ
  (`KKMCEE5/LEP1_qqbar_ISR/prodrun/setup_kkmc_env.sh`).

ThePEG 2.1.5, Herwig 7.1.5 and Sherpa 2.2.6 do not compile with GCC 11 as released (non-const comparators, a
macOS-only include). The fixes are in `HERWIG7/LEP1_qqbar_ISR/patches/` (ThePEG, Herwig) and
`SHERPA2/LEP1_qqbar_ISR/patches/` (Sherpa 2.2.6); none changes physics.
