#!/usr/bin/env bash
# Runtime environment of the Herwig 7.1.5 install in $MCF_PREFIX/herwig715 (source it).
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
export HERWIG_PREFIX=$MCF_PREFIX/herwig715
export PATH=$HERWIG_PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$HERWIG_PREFIX/lib:$HERWIG_PREFIX/lib64:${LD_LIBRARY_PATH:-}
export LHAPDF_DATA_PATH=$HERWIG_PREFIX/share/LHAPDF
echo "Herwig 7.1.5 environment loaded (prefix: $HERWIG_PREFIX)"
