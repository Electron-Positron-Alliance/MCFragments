#!/bin/bash
# run_production.sh: the Sherpa 2.2.6 production, 10 shards x NEVENTS (default 500000) per ISR state, MAXPAR (default
# 20) jobs at a time, in $MCF_PREFIX/sherpa226/run (made by setup.sh). Job j (1-10) = seed j = shard j-1. Each job
# runs in a freshly emptied directory sherpa_isr${S}_job$j with the card as Run.dat, so that Sherpa integrates
# before generating: a directory that already holds Results.db skips the integration and gives a different event
# sequence. events.hepmc2g is kept and converted to sherpa226_isr${S}_$((j-1)).root. SEEDS (default "1 2 ... 10")
# and STATES (default "0 1") select a subset.
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export NEVENTS=${NEVENTS:-500000}
MAXPAR=${MAXPAR:-20}
source "$HERE/env.sh"
cd "$MCF_PREFIX/sherpa226/run"
for S in ${STATES:-0 1}; do for j in ${SEEDS:-$(seq 1 10)}; do echo "$S $j"; done; done | xargs -P "$MAXPAR" -n 2 bash -c '
  S=$0; j=$1; i=$((j-1)); d=sherpa_isr${S}_job$j
  rm -rf "$d" && mkdir "$d" && cp Run_isr$S.dat "$d/Run.dat" \
    && (cd "$d" && Sherpa -e "$NEVENTS" -R "$j" > ../sherpa226_isr${S}_${i}.log 2>&1) \
    && ./hepmcToRoot -f "$d/events.hepmc2g" -o sherpa226_isr${S}_${i}.root > sherpa226_isr${S}_${i}_convert.log 2>&1 \
    && echo "isr$S seed $j -> sherpa226_isr${S}_${i}.root" || { echo "isr$S seed $j FAILED, see sherpa226_isr${S}_${i}*.log"; exit 255; }'
