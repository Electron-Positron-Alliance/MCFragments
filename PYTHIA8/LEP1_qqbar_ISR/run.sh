#!/usr/bin/env bash
# Usage: ./run.sh NJOBS SHOWER ISR [NEVT] [OUTDIR]
#   NJOBS  = number of parallel shards (e.g. 5)
#   SHOWER = 1 (simple), 2 (Vincia)
#   ISR    = 0 (off) or 1 (on)
#   NEVT   = events per shard (default 500000)
#   OUTDIR = where the .root and .log land (default .)
# MAXPAR caps concurrent shards (default NJOBS).

set -u

NJOBS=${1:-1}
SHOWER=${2:-1}
ISR=${3:-1}
NEVT=${4:-500000}
OUTDIR=${5:-.}
MAXPAR=${MAXPAR:-$NJOBS}

: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
PYTHIA=$MCF_PREFIX/pythia8317
# Use the data files of this PYTHIA 8.317 build, not any other PYTHIA on the system.
export PYTHIA8DATA=$PYTHIA/share/Pythia8/xmldoc

# Names must match the archived samples: bare for the simple shower, prefixed for Vincia.
declare -A SHOWER_TAG=( [1]="" [2]="vincia_" )
TAG=${SHOWER_TAG[$SHOWER]}

# Distinct seed block per (shower, ISR) group so no two shards anywhere share a seed.
declare -A SEED_BASE=( [1_1]=100000 [1_0]=200000 [2_1]=300000 [2_0]=400000 )
BASE=${SEED_BASE[${SHOWER}_${ISR}]}

OUTDIR=$(mkdir -p "$OUTDIR" && cd "$OUTDIR" && pwd)

PIDS=()
for i in $(seq 0 $((NJOBS - 1))); do
    while [ "$(jobs -rp | wc -l)" -ge "$MAXPAR" ]; do wait -n; done
    OUT="${OUTDIR}/pythia8317_${TAG}isr${ISR}_${i}.root"
    LOG="${OUTDIR}/pythia8317_${TAG}isr${ISR}_${i}.log"
    # main304 finds libpythia8 through the relative rpath ../lib, so it runs from examples/.
    (cd "$PYTHIA/examples" && exec ./main304 -o "$OUT" -n "$NEVT" -i "$ISR" -s "$SHOWER" -r $((BASE + i + 1))) > "$LOG" 2>&1 &
    PIDS+=($!)
done

# A failed shard does not stop the others; the script then exits nonzero.
RC=0
for i in "${!PIDS[@]}"; do
    wait "${PIDS[$i]}" || { echo "Shard $i FAILED, see ${OUTDIR}/pythia8317_${TAG}isr${ISR}_${i}.log"; RC=1; }
done
echo "All jobs finished."
exit $RC
