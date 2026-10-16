#!/usr/bin/env bash
export HERWIG_PREFIX=/home/badea/code/herwig715
export PATH=$HERWIG_PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$HERWIG_PREFIX/lib:$HERWIG_PREFIX/lib64:${LD_LIBRARY_PATH:-}
export LHAPDF_DATA_PATH=$HERWIG_PREFIX/share/LHAPDF
echo "Herwig 7.1.5 environment loaded (prefix: $HERWIG_PREFIX)"
