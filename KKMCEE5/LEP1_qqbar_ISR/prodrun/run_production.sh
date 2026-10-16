#!/bin/bash
# run_production.sh
# -----------------------------------------------------------------------------
# Launch the full Phase 2 KKMCee qqbar production:
#   10 shards x 500,000 events for ISR state 0  -> 5,000,000 events
#   10 shards x 500,000 events for ISR state 1  -> 5,000,000 events
#   = 20 shards total.
#
# Concurrency is capped at MAXPROC simultaneous shard processes via xargs -P.
# Each shard is single-threaded. Each shard writes its own log under LOGDIR.
# -----------------------------------------------------------------------------
set -u

PRODDIR=/home/badea/code/kkmcee/ProdRun
LOGDIR=/home/badea/code/kkmcee/qqbar_v2/logs
MAXPROC=20

mkdir -p "$LOGDIR"

echo "run_production: START $(date '+%F %T')  maxproc=$MAXPROC"
echo "run_production: 20 shards (isr0 x10, isr1 x10), 500k events each"

# Emit the job list: "STATE SHARD" per line, then run with a bounded pool.
# Each job logs to its own file: $LOGDIR/shard_isr{S}_{I}.log
for S in 0 1; do
  for I in $(seq 0 9); do
    echo "$S $I"
  done
done | xargs -P "$MAXPROC" -n 2 bash -c \
  'S="$0"; I="$1"; '"$PRODDIR"'/run_shard.sh "$S" "$I" > '"$LOGDIR"'/shard_isr${S}_${I}.log 2>&1'

echo "run_production: ALL SHARDS FINISHED $(date '+%F %T')"
echo "run_production: ROOT files:"
ls -la /home/badea/code/kkmcee/qqbar_v2/kkmcee_isr*.root 2>/dev/null | wc -l
