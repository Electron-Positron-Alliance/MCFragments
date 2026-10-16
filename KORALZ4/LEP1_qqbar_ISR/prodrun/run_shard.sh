#!/bin/bash
# run_shard.sh ISR_STATE SHARD_INDEX: one KORALZ qqbar shard of NEVENTS, hadronized exactly like the
# KKMCee shards (/home/badea/code/kkmcee/ProdRun/run_shard.sh + hadronizeKKMC). KORALZ makes one
# flavour per run, so the shard is 5 runs with N_q proportional to the pilot cross sections.
set -u
PRODDIR=/home/badea/code/koralz/ProdRun
OUTDIR=${OUTDIR:-/home/badea/code/koralz/qqbar}
HADRONIZE=/home/badea/code/kkmcee/ProdRun/hadronizeKKMC
NEVENTS=${NEVENTS:-500000}
S="$1"
I="$2"
source /home/badea/code/kkmcee/ProdRun/setup_kkmc_env.sh
WORK="${WORKROOT:-$PRODDIR}/prod_isr${S}_${I}"
OUTROOT="$OUTDIR/koralz_isr${S}_${I}.root"
rm -rf "$WORK"
mkdir -p "$WORK" "$OUTDIR"
cd "$WORK" || exit 99
# Events per flavour from the pilot sigma_q (pilot/p_q{q}_isr{S}.log), largest remainder to d.
read -r -a NQ <<< "$(for q in 1 2 3 4 5; do grep 'Total cross sections in nanobarns' "$PRODDIR/pilot/p_q${q}_isr${S}.log" | tail -1 | awk '{print $2}'; done | awk -v n=$NEVENTS '{s[NR]=$1; t+=$1} END {for(q=1;q<=5;q++){c[q]=int(n*s[q]/t); u+=c[q]} c[1]+=n-u; for(q=1;q<=5;q++) printf "%d ", c[q]}')"
[ "${#NQ[@]}" -eq 5 ] || { echo "[shard isr${S}_${I}] ERROR: pilot cross sections missing"; exit 1; }
echo "[shard isr${S}_${I}] START $(date '+%F %T') N(d,u,s,c,b) = ${NQ[*]}"
PARTS=()
for q in 1 2 3 4 5; do
  SEED=$(( 1000000 + S*100000 + I*10 + q ))
  N=${NQ[$((q-1))]}
  "$PRODDIR/MainKoralzHepMC" "$N" "q${q}.hepmc3" "$q" "$S" "$SEED" > "gen_q${q}.log" 2>&1 \
    || { echo "[shard isr${S}_${I}] ERROR: KORALZ q$q failed, see $WORK/gen_q${q}.log"; exit 1; }
  "$HADRONIZE" -f "q${q}.hepmc3" -o "q${q}.root" -n "$N" > "had_q${q}.log" 2>&1 \
    || { echo "[shard isr${S}_${I}] ERROR: hadronize q$q failed, see $WORK/had_q${q}.log"; exit 2; }
  rm -f "q${q}.hepmc3"
  PARTS+=("q${q}.root")
  echo "[shard isr${S}_${I}] q$q N=$N seed=$SEED $(tail -1 had_q${q}.log)"
done
hadd -f "$OUTROOT" "${PARTS[@]}" > hadd.log 2>&1 || { echo "[shard isr${S}_${I}] ERROR: hadd failed"; exit 3; }
rm -f "${PARTS[@]}"
echo "[shard isr${S}_${I}] DONE $(date '+%F %T') root=$(du -h "$OUTROOT" | cut -f1)"
