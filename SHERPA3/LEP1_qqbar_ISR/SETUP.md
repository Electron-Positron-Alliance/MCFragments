# Sherpa 3.0.5 (YFS ISR): LEP1 qqbar, ISR off / on

A study sample: drawn beside the C_ISR generators, not in the systematic envelope. It replaces Sherpa 2.2.6's collinear
electron structure function (`SHERPA2/LEP1_qqbar_ISR`) by YFS soft-photon resummation of the ISR. HepMC3 3.2.5: see the
top-level `README.md`.

Files:
- `Run_isr0.yaml`, `Run_isr1.yaml`: the cards. ISR off: `YFS: MODE: Off`; ISR on: `YFS: MODE: ISR`. Both have
  `PDF_LIBRARY: None` and massive electrons (YFS needs them). Otherwise they match the Sherpa 2.2.6 cards: beam energy
  45.594 GeV (sqrt(s) = 91.188 GeV), `ALPHAS(MZ): 0.1188`, process `11 -11 -> 93 93` at EW order 2. Output is native
  HepMC3 (`HEPMC3_IO_TYPE: 0`), because the HepMC2 output contains `-nan` values on which the HepMC2 reader silently
  stops.
- `hepmc3ToRoot.cc`: HepMC3 port of the Sherpa 2.2.6 / Herwig `hepmcToRoot.cc`, same `tgenBefore` tree. `-n N` exits
  with code 2 unless exactly N events were read; `-2` reads HepMC2 input. Beam particles are those with status 4;
  `pwflag` is written as 0 (the analysis derives it from `pdgid`).
- `run_shard.sh`, `run_production.sh`: one shard = one empty work directory, `Sherpa -e 500000 -R J`, then
  `hepmc3ToRoot -n 500000`; the HepMC3 file is deleted only after a full conversion.
- `keepall_beamblob_tag.patch`: the ISR-on keep-all variant (below).

Source: `https://gitlab.com/sherpa-team/sherpa/-/archive/v3.0.5/sherpa-v3.0.5.tar.gz`, sha256
`6c3804d48e1955ee82f713b3d3ffd16b013a9912752f488aab0ba6c1b1634288`. GCC 11.5.0, CMake 3.31.8.

Build (prefix `/home/badea/code/sherpa305`):
```sh
tar xzf sherpa-v3.0.5.tar.gz && mkdir build && cd build
cmake ../sherpa-v3.0.5 -DCMAKE_INSTALL_PREFIX=/home/badea/code/sherpa305 -DCMAKE_BUILD_TYPE=Release \
  -DSHERPA_ENABLE_LHAPDF=OFF -DSHERPA_ENABLE_INSTALL_LIBZIP=ON -DSHERPA_ENABLE_HEPMC3=ON \
  -DHepMC3_DIR=/home/badea/code/local/share/HepMC3/cmake
make -j24 && make install
cd <run dir> && g++ -O2 -std=c++17 -Wall hepmc3ToRoot.cc -o hepmc3ToRoot -I/home/badea/code/local/include \
  $(/usr/bin/root-config --cflags) -L/home/badea/code/local/lib64 -Wl,-rpath,/home/badea/code/local/lib64 -lHepMC3 \
  $(/usr/bin/root-config --libs)
```

Run: `./run_production.sh` runs `run_shard.sh S J` for S = 0, 1 and J = 1..10, 20 at a time: seed `J`, output
`sherpa305_isr${S}_$((J-1)).root`. Every shard starts from an empty directory, so Sherpa integrates before generating.

## ISR-on keep-all variant (the sample used for the C_ISR comparison)

With YFS ISR on, 2.49% of the events fail Sherpa's beam-blob momentum check (`Remnant_Handler::CheckBeamBreakup`,
tolerance 1e-6 x E_beam) and are replaced by new events. The rejection is not uniform in thrust: on the
production sample, dropping these events changes the normalized tau shape by +0.65 +- 0.03% in the first bin of the
analysis `tau_p30` binning (tau < 0.014), +0.35% and +0.09% in the next two, and -0.04% to -0.17% above.

The keep-all variant keeps these events and lists them. `keepall_beamblob_tag.patch` changes only
`REMNANTS/Main/Remnant_Handler.C`: a failed check no longer returns a new event but prints
`BEAMBLOB_FAIL <0-based event index>`. Build it as a separate library and preload it, leaving the installed Sherpa
unmodified (the installed libraries carry an RPATH, so `LD_LIBRARY_PATH` cannot override them):
```sh
cd sherpa-v3.0.5 && patch -p1 < keepall_beamblob_tag.patch && cd ../build && make Remnants
mkdir -p <run dir>/diag_tag && cp outputs/lib64/SHERPA-MC/libRemnants.so.0.0.0 <run dir>/diag_tag/
cd ../sherpa-v3.0.5 && patch -R -p1 < keepall_beamblob_tag.patch && cd ../build && make Remnants   # restore the build tree
for J in $(seq 1 10); do echo $J; done | VARIANT=keepall xargs -P 10 -I{} ./run_shard.sh 1 {}
```
Output: `sherpa305_keepall_isr1_$((J-1)).root` and `tags_keepall_isr1_$((J-1)).txt` (the tagged event indices; in the
production 124434 lines, 124428 distinct events). The C_ISR comparison uses the standard ISR-off sample (no event fails
the check with ISR off) and the keep-all ISR-on sample.

Event record: per beam, Sherpa 3 merges the YFS photons into one final-state photon and keeps the individual photons
with status 3, so an ISR photon count must use either the merged photons or the status-3 ones, not both.

## Verification (2026-10-16)

- 200 events each of isr0 seed 1, isr1 seed 1 and keep-all isr1 seed 1, rerun with these cards and scripts from empty
  directories, against shard 0 of the archived samples: all 30 branches identical (`y` identical including its NaN
  entries), and the same 8 tagged events.
- The patch applied to the 3.0.5 tarball source and built with `make Remnants` in the original build tree gives a
  library byte-identical to the one used for the production (sha256 `84ef082560c6011cc791355a1adfcd72c31926c8ba9551fc05fe5bdfcf7aa18b`).
- `hepmc3ToRoot` against the Sherpa 2.2.6 `hepmcToRoot`, on Sherpa 2.2.6 events (both converters) and on Sherpa 3
  events (native HepMC3 through `hepmc3ToRoot`, the same events written as HepMC2 through `hepmcToRoot`): event-level
  branches identical; particle records and mother/daughter links identical once particle ordering is ignored.
- ISR off: no event fails the beam-blob check (0 `MakeBeamBlobs failed` messages in the 10 production logs).
