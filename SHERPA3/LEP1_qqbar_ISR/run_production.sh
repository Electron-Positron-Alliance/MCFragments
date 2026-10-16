#!/bin/bash
# 10 shards x 500k events per ISR state (seeds 1..10), MAXPROC concurrent single-threaded shards.
set -u
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LOGDIR=$MCF_PREFIX/sherpa305/qqbar/logs
MAXPROC=${MAXPROC:-20}
mkdir -p "$LOGDIR"
echo "run_production: START $(date '+%F %T') maxproc=$MAXPROC"
for S in 0 1; do for J in $(seq 1 10); do echo "$S $J"; done; done | xargs -P "$MAXPROC" -n 2 bash -c \
  'S="$0"; J="$1"; '"$HERE"'/run_shard.sh "$S" "$J" > '"$LOGDIR"'/shard_isr${S}_job${J}.log 2>&1'
echo "run_production: ALL SHARDS FINISHED $(date '+%F %T')"
ls "$MCF_PREFIX"/sherpa305/qqbar/sherpa305_isr*.root 2>/dev/null | wc -l
