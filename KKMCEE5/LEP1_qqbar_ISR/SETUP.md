# KKMCee 5 (ISR) + PYTHIA 8.317 (FSR + hadronization): LEP1 qqbar, ISR off / on

The C_ISR reference generator. Platform and shared dependencies (HepMC3, PHOTOS++): see the top-level `README.md`.

Files:
- `prodrun/workQQ2_isr0/pro.input`, `prodrun/workQQ2_isr1/pro.input`: the two production cards. They differ only in
  `KeyISR = xpar(20)` (0 / 1). FSR in KKMCee is off (`xpar(21)=0`); PYTHIA does it. Events are unweighted
  (`xpar(10)=0`).
- `prodrun/workQQ2_dizet/`: the 5-quark DIZET electroweak table the production read (`DIZET-table1.xz`, xz-compressed;
  sha256 of the uncompressed file `28788f8f7a8ff36db89658a6b869c95944f1fe8d3546d8658fbd243725cdcf49`), with the card
  that made it (`pro.input`) and the tabulation output (`tab.log`, `TabMain77.output`).
- `prodrun/MainHepMC.cxx`: KKMCee -> HepMC3, seed from `KKMC_SEED`.
- `prodrun/hadronizeKKMC.cc`: PYTHIA 8.317 FSR + hadronization of the KKMCee (and KORALZ) HepMC3 events, default
  Monash tune, writes the `tgenBefore` ntuple.
- `prodrun/run_shard.sh`, `prodrun/run_production.sh`, `prodrun/setup_kkmc_env.sh`.
- `KKMCee_defaults`: unmodified upstream `SRCee/KKMCee_defaults` at the commit below, for reference.
- `build_logs/`: KKMCee autoreconf/configure and PHOTOS++ configure output. KKMCee's `config.log` is left out (it
  records the build host); its invocation line is the `./configure` command below.

Source: github.com/KrakowHEPSoft/KKMCee, git `bf3cce7f4326c34de81a39daf30fadbb6836bd94` (unmodified).

Build:
```sh
git clone https://github.com/KrakowHEPSoft/KKMCee && cd KKMCee && git checkout bf3cce7f4326c34de81a39daf30fadbb6836bd94
source <ROOT 6.36.04>/bin/thisroot.sh
autoreconf -i   # exact flags not recorded; output in build_logs/kkmcee_autoreconf.log
./configure CXXFLAGS="-std=c++17 -g -O2" --with-hepmc=/home/badea/code/local --with-photos=/home/badea/code/local/photos
make
cp -r <this folder>/prodrun/* ProdRun/ && cd ProdRun && unxz workQQ2_dizet/DIZET-table1.xz
K=$(cd .. && pwd); RL="-L<ROOT 6.36.04>/lib -lGui -lCore -lImt -lRIO -lNet -lHist -lGraf -lGraf3d -lGpad -lROOTVecOps -lTree -lTreePlayer -lRint -lPostscript -lMatrix -lPhysics -lMathCore -lThread -lROOTNTuple -lMultiProc -lROOTDataFrame -lROOTNTupleUtil"
g++ -std=c++17 -g -O2 -I$K -I$K/SRCee -I$K/MCdev -I$K/Foam2 -I<ROOT 6.36.04>/include -I/home/badea/code/local/include \
  -I/home/badea/code/local/photos/include MainHepMC.cxx -o MainHepMC \
  -L$K/SRCee/.libs -lKKee -L$K/tauola-photos/.libs -lTauolaPhotos -L$K/MCdev/.libs -lMCdev -L$K/Foam2/.libs -lFOAM $RL \
  -L/home/badea/code/local/photos/lib -lPhotosppHepMC3 -lPhotosppHEPEVT -lPhotospp -L/home/badea/code/local/lib64 -lHepMC3 -lgfortran -lquadmath \
  -Wl,-rpath,/home/badea/code/local/lib64:$K/SRCee/.libs:$K/tauola-photos/.libs:$K/MCdev/.libs:$K/Foam2/.libs:/home/badea/code/local/photos/lib
g++ -std=c++17 -O2 hadronizeKKMC.cc -o hadronizeKKMC -I<pythia8317>/include -I/home/badea/code/local/include $(/usr/bin/root-config --cflags) \
  -L<pythia8317>/lib -lpythia8 -L/home/badea/code/local/lib64 -lHepMC3 $(/usr/bin/root-config --libs) \
  -Wl,-rpath,/usr/lib64/root:<pythia8317>/lib:/home/badea/code/local/lib64
```
The two `g++` commands were reconstructed (the originals were not recorded); binaries built with them reproduce the
archived events exactly (see Verification).

Run: `./run_production.sh` (20 shards, 20 at a time). Shard `I` (0-9) of ISR state `S` runs in `ProdRun/prod2_isr${S}_${I}`
with seed `1000000 + 100000*S + I + 1`: `MainHepMC 500000`, then `hadronizeKKMC`, then the temporary HepMC3 file is
deleted. Output: `kkmcee_isr${S}_${I}.root`.

Known difference: `hadronizeKKMC` does not set a PYTHIA seed, so every KKMCee shard (and every KORALZ shard and flavour
part) hadronizes with PYTHIA's default seed (19780503). This is what was run.

History: a first KKMCee production (v1, weighted events `xpar(10)=1` and a mu-only DIZET table) was the C_ISR reference
until 2026-10-02. It is superseded by this one and not included.

## Verification (2026-10-08)

Rebuilt `MainHepMC` and `hadronizeKKMC` with the commands above; 300 events of isr1 shard 0 give an ntuple identical
to the archived one (30 branches).
