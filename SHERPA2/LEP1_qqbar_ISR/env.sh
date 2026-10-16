#!/usr/bin/env bash
export SHERPA_PREFIX=/home/badea/code/sherpa226
export PATH=$SHERPA_PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$SHERPA_PREFIX/lib:$SHERPA_PREFIX/lib64:${LD_LIBRARY_PATH:-}
export LHAPDF_DATA_PATH=$SHERPA_PREFIX/share/LHAPDF
echo "Sherpa 2.2.6 environment loaded (prefix: $SHERPA_PREFIX)"
