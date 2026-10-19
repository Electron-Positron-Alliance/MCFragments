#!/bin/bash
# setup_kkmc_env.sh: runtime environment of the KKMCee (and KORALZ) qqbar production. Source it before running
# MainHepMC, hadronizeKKMC or TabMainC.
#
# MainHepMC (built against the ROOT 6.36.04 release, whose libraries are unversioned) and hadronizeKKMC (built against
# the system ROOT 6.38.04) both run against the system ROOT 6.38.04 in /usr/lib64/root, for ROOTSYS and
# LD_LIBRARY_PATH alike. Do not source $MCF_PREFIX/root/bin/thisroot.sh here: mixing the two ROOTs aborts
# hadronizeKKMC inside libCling ("free(): invalid pointer").
: "${MCF_PREFIX:?set MCF_PREFIX to the install root}"
export ROOTSYS=/usr
export LD_LIBRARY_PATH=/usr/lib64/root:$MCF_PREFIX/local/lib64:$MCF_PREFIX/local/photos/lib:$MCF_PREFIX/pythia8317/lib:${LD_LIBRARY_PATH:-}
export PYTHIA8DATA=$MCF_PREFIX/pythia8317/share/Pythia8/xmldoc
