#!/usr/bin/env bash
set -eo pipefail

#
# Build the dependencies in CODE which need compiling, and install them into CODE/install.
# HepPDT and EvtGen are only needed to build k4Gen, which the v3.2 container lacks.
# Run after fetch_deps.sh, inside the container, e.g.:
#
#   apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v3.2-amd64 ./setup/build_deps.sh
#

CODE=${MAIA_MLPF_CODE:-"/ceph/users/atuna/work/maia/maia_mlpf"}
INSTALL=${CODE}/install
JOBS=4

#
# setup if necessary
#
if [ ! -f /opt/setup_mucoll.sh ]; then
    echo "Error: run this inside the container"
    exit 1
fi
if ! command -v ddsim >/dev/null 2>&1; then
    source /opt/setup_mucoll.sh
fi

cd ${CODE}

#
# HepPDT
#
echo "Building HepPDT ..."
cd HepPDT-2.06.01
./configure --prefix=${INSTALL}
make -j${JOBS}
make install
cd ${CODE}

#
# EvtGen
#
echo "Building EvtGen ..."
mkdir -p EvtGen/build
cd EvtGen/build
cmake .. \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=${INSTALL} \
    -DEVTGEN_HEPMC3=ON \
    -DEVTGEN_PYTHIA=ON \
    -DEVTGEN_PHOTOS=OFF \
    -DEVTGEN_TAUOLA=OFF
make -j${JOBS} install
cd ${CODE}

#
# k4Gen
#
echo "Building k4Gen ..."
mkdir -p k4Gen/build
cd k4Gen/build
cmake .. \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=${INSTALL} \
    -DCMAKE_PREFIX_PATH=${INSTALL} \
    -DBUILD_TESTING=OFF
make -j${JOBS} install
cd ${CODE}

echo "Done. Built HepPDT, EvtGen, and k4Gen into ${INSTALL}"
