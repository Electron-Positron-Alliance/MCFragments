#!/bin/bash
# ROOT 6.36.04 binary release -> $MCF_PREFIX/root. Source $MCF_PREFIX/root/bin/thisroot.sh before building PYTHIA 8.317,
# KKMCee and MainHepMC. The ntuple converters and hadronizeKKMC use the system ROOT 6.38.04 instead (README.md).
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
T=root_v6.36.04.Linux-almalinux9.6-x86_64-gcc11.5.tar.gz
"$HERE/fetch.sh" $T
rm -rf "$MCF_PREFIX/root"
tar xzf "$MCF_PREFIX/src/$T" -C "$MCF_PREFIX"
echo "setup_root.sh: ROOT $("$MCF_PREFIX/root/bin/root-config" --version) in $MCF_PREFIX/root"
