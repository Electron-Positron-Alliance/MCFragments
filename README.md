# MCFragments
Contains the MC fragments utilized to generate simulations used by the EPA. 

## LEP1 e+e- -> qqbar with QED ISR on/off (`*/LEP1_qqbar_ISR/`)

Paired ISR-off (`isr0`) / ISR-on (`isr1`) samples of e+e- -> qqbar (5 flavours) at the Z pole, used for the ALEPH
thrust QED ISR correction C_ISR = (ISR off) / (ISR on). Each sample is 10 shards x 500k events per ISR state, written
as a `tgenBefore` ntuple with the branch layout of `PYTHIA8/LEP1_qqbar_ISR/main304.cc`. The correction itself is computed
in the analysis (`ALEPH_Analysis_EventShapes`: inputs in `Studies/thrust/base.yaml`, `isr_generators` and
`isr_cross_checks`; code in `Unfolding/thrust/scripts/compute_isr_correction.py`).

| Generator | sqrt(s) [GeV] | ISR off / on | Role in C_ISR | Folder |
|---|---|---|---|---|
| KKMCee 5 (ISR) + PYTHIA 8.317 (FSR + hadronization) | 91.1876 | `KeyISR` = `xpar(20)` 0 / 1 | reference (nominal) | `KKMCEE5/LEP1_qqbar_ISR` |
| KORALZ 4.04 (ISR) + the same PYTHIA 8.317 hadronizer | 91.1876 | `KEYRAD` 0 / 12 | cross-check, drawn only | `KORALZ4/LEP1_qqbar_ISR` |
| PYTHIA 8.317, simple shower | 91.1876 | `PDF:lepton`, `PartonLevel:ISR` off / on | envelope | `PYTHIA8/LEP1_qqbar_ISR` |
| PYTHIA 8.317, Vincia shower | 91.1876 | as above | envelope | `PYTHIA8/LEP1_qqbar_ISR` (`-s 2`) |
| Herwig 7.1.5 | 91.188 | `NoPDF` + `DoISR No` / `LeptonPDF` + `DoISR Yes` | envelope | `HERWIG7/LEP1_qqbar_ISR` |
| Sherpa 2.2.6 | 91.188 | `PDF_LIBRARY None` / `BUNCH_1 11; BUNCH_2 -11` | envelope | `SHERPA2/LEP1_qqbar_ISR` |
| Sherpa 3.0.5 | 91.188 | `YFS: MODE: Off` / `ISR` | study only, not in the envelope | `SHERPA3/LEP1_qqbar_ISR` |
| PYTHIA 6.1 (archived ALEPH 1994 MC), conversion-cleaned / uncleaned | | | cross-check, drawn only | not here: official ALEPH MC |

Each folder has a `SETUP.md` (build, run, seeds, how the files were checked) and exact copies of the files that made
the samples. The scripts contain absolute paths under `/home/badea/code/...`: either install into the same layout or edit
the `PRODDIR`/`PREFIX`/`OUTDIR`/`RUN` variables at the top of each script.

### Platform

RHEL 9.8 (x86_64), GCC/gfortran 11.5.0. Two ROOT installs are used, deliberately:
- ROOT 6.36.04 binary release (`root_v6.36.04.Linux-almalinux9.6-x86_64-gcc11.5.tar.gz`, sha256 `80a1f40e...6e5a2b`):
  `root-config` on PATH when building PYTHIA 8.317, KKMCee and `MainHepMC`.
- ROOT 6.38.04 system package (`root-core-6.38.04-5.el9`, `/usr/lib64/root`): used to build `hadronizeKKMC`, the
  Herwig/Sherpa 2 `hepmcToRoot` and the Sherpa 3 `hepmc3ToRoot`, and at runtime for KKMCee/KORALZ
  (`KKMCEE5/LEP1_qqbar_ISR/prodrun/setup_kkmc_env.sh`).

### Shared dependencies (prefix `/home/badea/code/local`)

| Package | Version | File | sha256 |
|---|---|---|---|
| HepMC3 | 3.2.5 | `HepMC3-3.2.5.tar.gz` | `cd0f75c80f75549c59cc2a829ece7601c77de97cb2a5ab75790cac8e1d585032` |
| PHOTOS++ | 3.64 | `PHOTOS.3.64.tar.gz` | `92c545d83c0f654ca40949c7e36e79a96230421659a4621cd9ae9c82dd5a30ee` |

```sh
# HepMC3 3.2.5: cmake, CMAKE_INSTALL_PREFIX=/home/badea/code/local, HEPMC3_ENABLE_ROOTIO=OFF
# PHOTOS++ 3.64:
./configure --with-hepmc3=/home/badea/code/local --without-hepmc --prefix=/home/badea/code/local/photos CXXFLAGS="-std=c++11 -g -O2"
```
HepMC3 is used by KKMCee, KORALZ and Sherpa 3; PHOTOS++ by KKMCee.
