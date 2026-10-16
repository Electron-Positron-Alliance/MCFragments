#!/bin/bash
# 10 shards x 500k events per ISR state, MAXPROC concurrent (single-threaded) shards.
set -u
PRODDIR=/home/badea/code/koralz/ProdRun
LOGDIR=/home/badea/code/koralz/qqbar/logs
MAXPROC=${MAXPROC:-20}
mkdir -p "$LOGDIR"
echo "run_production: START $(date '+%F %T') maxproc=$MAXPROC"
for S in 0 1; do for I in $(seq 0 9); do echo "$S $I"; done; done | xargs -P "$MAXPROC" -n 2 bash -c \
  'S="$0"; I="$1"; '"$PRODDIR"'/run_shard.sh "$S" "$I" > '"$LOGDIR"'/shard_isr${S}_${I}.log 2>&1'
echo "run_production: ALL SHARDS FINISHED $(date '+%F %T')"
ls /home/badea/code/koralz/qqbar/koralz_isr*.root 2>/dev/null | wc -l
