#!/bin/bash
# run_shard.sh ISR_STATE JOB: one Sherpa 3.0.5 qqbar shard (YFS ISR off/on), seed = JOB, shard index = JOB-1,
# in an empty directory so Sherpa integrates first. The HepMC3 file is deleted only after hepmc3ToRoot has read
# exactly NEVENTS events.
# VARIANT=keepall preloads diag_tag/libRemnants (keeps the ~2.5% of ISR-on events Sherpa's beam-blob momentum check
# rejects, and lists their 0-based event indices in tags_*.txt next to the ntuple).
set -u
RUN=/home/badea/code/sherpa305/run
OUTDIR=${OUTDIR:-/home/badea/code/sherpa305/qqbar}
NEVENTS=${NEVENTS:-500000}
VARIANT=${VARIANT:-}
S="$1"
J="$2"
export PATH=/home/badea/code/sherpa305/bin:$PATH
export LD_LIBRARY_PATH=/home/badea/code/sherpa305/lib64:/home/badea/code/local/lib64
TAG=${VARIANT:+${VARIANT}_}
PRELOAD=""
[ "$VARIANT" = keepall ] && PRELOAD="$RUN/diag_tag/libRemnants.so.0.0.0"
[ -n "$VARIANT" ] && [ -z "$PRELOAD" ] && { echo "unknown VARIANT=$VARIANT"; exit 98; }
WORK="$RUN/prod_${TAG}isr${S}_job${J}"
OUTROOT="$OUTDIR/sherpa305_${TAG}isr${S}_$((J-1)).root"
rm -rf "$WORK"
mkdir -p "$WORK" "$OUTDIR"
cd "$WORK" || exit 99
cp "$RUN/Run_isr${S}.yaml" Sherpa.yaml
echo "[isr${S} job${J}] START $(date '+%F %T') seed=$J nevents=$NEVENTS"
LD_PRELOAD="$PRELOAD" Sherpa -e "$NEVENTS" -R "$J" > sherpa.log 2>&1 || { echo "[isr${S} job${J}] ERROR: Sherpa failed, see $WORK/sherpa.log"; exit 1; }
"$RUN/hepmc3ToRoot" -f events -o "$OUTROOT" -n "$NEVENTS" > conv.log 2>&1 \
  || { echo "[isr${S} job${J}] ERROR: conversion failed, see $WORK/conv.log (events kept)"; exit 2; }
rm -f events
[ -n "$PRELOAD" ] && grep -o 'BEAMBLOB_FAIL [0-9]*' sherpa.log | awk '{print $2}' > "$OUTDIR/tags_${TAG}isr${S}_$((J-1)).txt"
echo "[isr${S} job${J}] DONE $(date '+%F %T') root=$(du -h "$OUTROOT" | cut -f1)"
