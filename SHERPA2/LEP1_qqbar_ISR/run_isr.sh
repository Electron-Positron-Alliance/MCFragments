#!/usr/bin/env bash
# Run Sherpa 2.2.6 for both ISR=0 and ISR=1 at LEP1
# Usage: bash run_isr.sh [isr]   (isr=0 or 1, default runs both)

set -e
source /home/badea/code/sherpa226/env.sh

RUNDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$RUNDIR"

NCORE=5
NEVT=500000

run_sherpa() {
    local ISR=$1
    local RUNDAT="Run_isr${ISR}.dat"

    echo "=== Sherpa ISR=${ISR} ==="

    # Build converter if needed
    [ -f hepmcToRoot ] || make

    # Run NCORE parallel jobs, each in own subdirectory
    pids=()
    for i in $(seq 1 $NCORE); do
        JOBDIR="sherpa_isr${ISR}_job${i}"
        mkdir -p "$JOBDIR"
        cp "$RUNDAT" "$JOBDIR/Run.dat"
        (cd "$JOBDIR" && Sherpa -e ${NEVT} -R ${i} 2>&1) > sherpa_isr${ISR}_${i}.log 2>&1 &
        pids+=($!)
    done
    for pid in "${pids[@]}"; do wait $pid || echo "WARNING: PID $pid non-zero exit"; done
    echo "All ISR=${ISR} Sherpa jobs done."

    # Convert HepMC -> ROOT
    echo "Converting HepMC -> ROOT for ISR=${ISR}..."
    pids=()
    for i in $(seq 1 $NCORE); do
        JOBDIR="sherpa_isr${ISR}_job${i}"
        HEPMC="${JOBDIR}/events.hepmc2g"
        ROOT_OUT="sherpa_isr${ISR}_${i}.root"
        if [ -f "$HEPMC" ]; then
            ./hepmcToRoot -f "$HEPMC" -o "$ROOT_OUT" > sherpa_isr${ISR}_${i}_convert.log 2>&1 &
            pids+=($!)
        else
            echo "WARNING: $HEPMC not found"
        fi
    done
    for pid in "${pids[@]}"; do wait $pid; done
    echo "ISR=${ISR} conversion done. Files: $(ls sherpa_isr${ISR}_*.root 2>/dev/null | tr '\n' ' ')"
}

if [ "$1" = "0" ]; then
    run_sherpa 0
elif [ "$1" = "1" ]; then
    run_sherpa 1
else
    run_sherpa 0
    run_sherpa 1
fi

echo "All Sherpa runs complete."
