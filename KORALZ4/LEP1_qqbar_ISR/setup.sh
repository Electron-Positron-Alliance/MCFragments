#!/bin/bash
# KORALZ 4.04 (CPC ACBK_v3_0 + patches/) and its production driver -> $MCF_PREFIX/koralz.
# Needs common/setup_hepmc3.sh and KKMCEE5/LEP1_qqbar_ISR/setup.sh (the shards are hadronized by KKMCee's
# hadronizeKKMC). Run with $MCF_PREFIX/koralz/ProdRun/run_production.sh.
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[ -x "$MCF_PREFIX/kkmcee/ProdRun/hadronizeKKMC" ] || { echo "setup.sh: run KKMCEE5/LEP1_qqbar_ISR/setup.sh first" >&2; exit 1; }
"$HERE/../../common/fetch.sh" acbk_v3_0.tar.gz
Z=$MCF_PREFIX/koralz
rm -rf "$Z"
mkdir -p "$Z"
cd "$Z"
tar xzf "$MCF_PREFIX/src/acbk_v3_0.tar.gz"
G=(git -c user.name="MCFragments setup" -c user.email=setup@localhost)
"${G[@]}" init -q
"${G[@]}" add -A
"${G[@]}" commit -q -m "KORALZ 4.04 CPC ACBK_v3_0"
"${G[@]}" am -q "$HERE"/patches/*.patch
sh build_gfortran.sh            # libraries + demos; add --validate to compare with the 1999 references
cd ProdRun
make
echo "setup.sh: KORALZ ready in $Z/ProdRun"
