#!/usr/bin/env bash
# Runtime environment of the Sherpa 2.2.6 install in $MCF_PREFIX/sherpa226 (source it).
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
export SHERPA_PREFIX=$MCF_PREFIX/sherpa226
export PATH=$SHERPA_PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$SHERPA_PREFIX/lib:$SHERPA_PREFIX/lib64:${LD_LIBRARY_PATH:-}
export LHAPDF_DATA_PATH=$SHERPA_PREFIX/share/LHAPDF
echo "Sherpa 2.2.6 environment loaded (prefix: $SHERPA_PREFIX)"
