#!/usr/bin/env bash
# Run Herwig 7.1.5 for both ISR=0 and ISR=1 at LEP1
# Usage: bash run_isr.sh [isr]   (isr=0 or 1, default runs both sequentially)

set -e
source /home/badea/code/herwig715/env.sh

RUNDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$RUNDIR"

NCORE=5
NEVT=500000

run_herwig() {
    local ISR=$1
    local RUNCARD="lep1_isr${ISR}.in"
    local RUNFILE="lep1_isr${ISR}.run"

    echo "=== Herwig ISR=${ISR} ==="

    # Step 1: Read runcard
    if [ ! -f "$RUNFILE" ]; then
        echo "Reading $RUNCARD ..."
        Herwig read "$RUNCARD"
    else
        echo "$RUNFILE exists, skipping read."
    fi

    # Step 2: Parallel run
    echo "Starting $NCORE jobs ($NEVT events each)..."
    pids=()
    for i in $(seq 1 $NCORE); do
        Herwig run "$RUNFILE" -N ${NEVT} -s ${i} > herwig_isr${ISR}_${i}.log 2>&1 &
        pids+=($!)
    done
    for pid in "${pids[@]}"; do wait $pid || echo "WARNING: PID $pid non-zero exit"; done
    echo "All ISR=${ISR} Herwig jobs done."

    # Step 3: Build converter if needed
    [ -f hepmcToRoot ] || make

    # Step 4: Convert HepMC -> ROOT
    echo "Converting HepMC -> ROOT for ISR=${ISR}..."
    pids=()
    for i in $(seq 1 $NCORE); do
        HEPMC="lep1_isr${ISR}-S${i}.hepmc"
        ROOT_OUT="herwig_isr${ISR}_${i}.root"
        if [ -f "$HEPMC" ]; then
            ./hepmcToRoot -f "$HEPMC" -o "$ROOT_OUT" > herwig_isr${ISR}_${i}_convert.log 2>&1 &
            pids+=($!)
        else
            echo "WARNING: $HEPMC not found"
        fi
    done
    for pid in "${pids[@]}"; do wait $pid; done
    echo "ISR=${ISR} conversion done. Files: $(ls herwig_isr${ISR}_*.root 2>/dev/null | tr '\n' ' ')"
}

if [ "$1" = "0" ]; then
    run_herwig 0
elif [ "$1" = "1" ]; then
    run_herwig 1
else
    run_herwig 0
    run_herwig 1
fi

echo "All Herwig runs complete."
