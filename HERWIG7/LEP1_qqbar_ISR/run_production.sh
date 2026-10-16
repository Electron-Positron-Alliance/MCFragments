#!/bin/bash
# run_production.sh: the Herwig 7.1.5 production, 10 shards x NEVENTS (default 500000) per ISR state, MAXPAR (default
# 20) jobs at a time, in $MCF_PREFIX/herwig715/run (made by setup.sh). Shard i (0-9) uses seed i+1, the same seeds for
# isr0 and isr1: `Herwig run lep1_isr$S.run -N NEVENTS -s i+1` writes lep1_isr$S-S$((i+1)).hepmc (kept), which
# hepmcToRoot converts to herwig715_isr${S}_${i}.root. SEEDS (default "1 2 ... 10") and STATES (default "0 1") select
# a subset.
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export NEVENTS=${NEVENTS:-500000}
MAXPAR=${MAXPAR:-20}
source "$HERE/env.sh"
cd "$MCF_PREFIX/herwig715/run"
for S in ${STATES:-0 1}; do Herwig read lep1_isr$S.in > read_isr$S.log 2>&1; done
for S in ${STATES:-0 1}; do for j in ${SEEDS:-$(seq 1 10)}; do echo "$S $j"; done; done | xargs -P "$MAXPAR" -n 2 bash -c '
  S=$0; j=$1; i=$((j-1))
  Herwig run lep1_isr$S.run -N "$NEVENTS" -s "$j" > herwig715_isr${S}_${i}.log 2>&1 \
    && ./hepmcToRoot -f lep1_isr$S-S$j.hepmc -o herwig715_isr${S}_${i}.root > herwig715_isr${S}_${i}_convert.log 2>&1 \
    && echo "isr$S seed $j -> herwig715_isr${S}_${i}.root" || { echo "isr$S seed $j FAILED, see herwig715_isr${S}_${i}*.log"; exit 255; }'
