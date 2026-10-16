#!/bin/bash
# run_shard.sh  ISR_STATE  SHARD_INDEX
# -----------------------------------------------------------------------------
# Generate ONE production shard of KKMCee qqbar -> Pythia8 hadronized events.
#
#   ISR_STATE   : 0 (KeyISR=0) or 1 (KeyISR=1)
#   SHARD_INDEX : 0..9
#
# Per shard: NEVENTS events -> temp HepMC3 -> hadronizeKKMC -> ROOT ntuple in
# OUTDIR, then the temp HepMC3 is deleted (to bound disk). Each shard runs in
# its own scratch work dir (cards + DIZET table) so shards do not collide.
#
# Seed independence: the central KKMCee TRandom3 seed is set via KKMC_SEED,
# varied per (ISR_STATE, SHARD_INDEX) so every shard is statistically
# independent. See MainHepMC.cxx (seed = argv[3] | $KKMC_SEED | default).
# -----------------------------------------------------------------------------
set -u

: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
PRODDIR=$MCF_PREFIX/kkmcee/ProdRun
OUTDIR=${OUTDIR:-$MCF_PREFIX/kkmcee/qqbar_v2}
NEVENTS=${NEVENTS:-500000}

S="$1"      # ISR state
I="$2"      # shard index

source "$PRODDIR/setup_kkmc_env.sh"

# Unique, reproducible seed per (state, shard). Base offset keeps isr0/isr1
# seed ranges disjoint; +1 guarantees a non-trivial seed.
SEED=$(( 1000000 + S*100000 + I*1 + 1 ))

WORK="$PRODDIR/prod2_isr${S}_${I}"
TMPHEP="$WORK/kkmcee_isr${S}_${I}.hepmc3"
OUTROOT="$OUTDIR/kkmcee_isr${S}_${I}.root"

rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK" || exit 99

# Cards: defaults + per-ISR pro.input (unweighted, KeyWgt=0) + the 5-quark DIZET table from workQQ2_dizet.
ln -sf "$PRODDIR/../SRCee/KKMCee_defaults" KKMCee_defaults
ln -sf "$PRODDIR/workQQ2_dizet/DIZET-table1" DIZET-table1
cp "$PRODDIR/workQQ2_isr${S}/pro.input"    pro.input

echo "[shard isr${S}_${I}] START $(date '+%F %T')  seed=$SEED  nevents=$NEVENTS"
echo "[shard isr${S}_${I}] work=$WORK"
echo "[shard isr${S}_${I}] out=$OUTROOT"

# ---- Stage 1: KKMCee parton-level generation -------------------------------
KKMC_SEED="$SEED" "$PRODDIR/MainHepMC" "$NEVENTS" "$TMPHEP" > gen.log 2>&1
RC=$?
if [ $RC -ne 0 ] || [ ! -s "$TMPHEP" ]; then
    echo "[shard isr${S}_${I}] ERROR: MainHepMC failed (rc=$RC). See $WORK/gen.log"
    exit 1
fi
echo "[shard isr${S}_${I}] gen DONE $(date '+%F %T')  hepmc=$(du -h "$TMPHEP" | cut -f1)"

# ---- Stage 2: hadronize + ntuple -------------------------------------------
"$PRODDIR/hadronizeKKMC" -f "$TMPHEP" -o "$OUTROOT" -n "$NEVENTS" > had.log 2>&1
RC=$?
if [ $RC -ne 0 ] || [ ! -s "$OUTROOT" ]; then
    echo "[shard isr${S}_${I}] ERROR: hadronizeKKMC failed (rc=$RC). See $WORK/had.log"
    exit 2
fi
echo "[shard isr${S}_${I}] had DONE $(date '+%F %T')  $(tail -1 had.log)"

# ---- Cleanup: drop the (large) temp HepMC3 ---------------------------------
rm -f "$TMPHEP"
echo "[shard isr${S}_${I}] DONE  removed temp hepmc; root=$(du -h "$OUTROOT" | cut -f1)  $(date '+%F %T')"
