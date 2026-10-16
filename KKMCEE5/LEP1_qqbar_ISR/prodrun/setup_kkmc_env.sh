#!/bin/bash
# setup_kkmc_env.sh
# -----------------------------------------------------------------------------
# Pinned runtime environment for the KKMCee qqbar production pipeline.
#
# CRITICAL: KKMCee binaries (MainHepMC) and the hadronizeKKMC driver run against
# the SYSTEM ROOT in /usr/lib64/root (version 6.38.04) -- NOT /home/badea/root.
# Do NOT source /home/badea/root/bin/thisroot.sh: it breaks MainHepMC.
#
# IMPORTANT (discovered during Phase 2 setup): there are TWO ROOT installs on
# this machine:
#     /usr/lib64/root   -> ROOT 6.38.04  (the real system package)
#     /etc/root         -> ROOT 6.36.04  (a second, older install)
# They MUST NOT be mixed. hadronizeKKMC uses TFile, which initialises Cling;
# if ROOTSYS points at /etc/root (6.36) while LD_LIBRARY_PATH loads the 6.38
# libs from /usr/lib64/root, the process aborts ("free(): invalid pointer",
# crash inside libCling). The consistent, working configuration is to use the
# 6.38 install for BOTH ROOTSYS and LD_LIBRARY_PATH, which is what is set below.
# Both MainHepMC and hadronizeKKMC were rebuilt against and verified under it.
#
# Source this script before building or running any of:
#   MainHepMC, hadronizeKKMC
# -----------------------------------------------------------------------------

export ROOTSYS=/usr
export LD_LIBRARY_PATH=/usr/lib64/root:/home/badea/code/local/lib64:/home/badea/code/local/photos/lib:/home/badea/code/pythia8317/lib:$LD_LIBRARY_PATH
export PYTHIA8DATA=/home/badea/code/pythia8317/share/Pythia8/xmldoc
