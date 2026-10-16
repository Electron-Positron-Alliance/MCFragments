#!/bin/bash
# PYTHIA 8.317 + main304 -> $MCF_PREFIX/pythia8317 (needs common/setup_root.sh). Run with run.sh.
set -euo pipefail
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
"$HERE/../../common/fetch.sh" pythia8317.tgz
set +u; source "$MCF_PREFIX/root/bin/thisroot.sh"; set -u   # the Makefile calls root-config from PATH
cd "$MCF_PREFIX"
rm -rf pythia8317
tar xzf src/pythia8317.tgz
cd pythia8317
./configure --with-root="$MCF_PREFIX/root"
make -j "${MCF_JOBS:-$(nproc)}"
# main304 joins the examples/Makefile rule for the ROOT examples.
cp "$HERE/main304.cc" examples/
cd examples
grep -q '^main141 main143: ' Makefile || { echo "setup.sh: examples/Makefile has no main141/main143 rule" >&2; exit 1; }
sed -i 's/^main141 main143: /main141 main143 main304: /' Makefile
make main304
echo "setup.sh: built $MCF_PREFIX/pythia8317/examples/main304"
