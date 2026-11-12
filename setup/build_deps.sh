#!/usr/bin/env bash
set -eo pipefail

#
# Build the dependencies in CODE which need compiling (MyBIBUtils, LCContent).
# Run after fetch_deps.sh, inside the container, e.g.:
#
#   apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v2.9.8-amd64 ./setup/build_deps.sh
#

CODE=${MAIA_MLPF_CODE:-"/ceph/users/atuna/work/maia/maia_mlpf"}
JOBS=4

#
# setup if necessary
#
if [ ! -d /opt/spack ]; then
    echo "Error: run this inside the container"
    exit 1
fi
if ! command -v ddsim >/dev/null 2>&1; then
    source /opt/spack/opt/spack/__spack_path_placeholder__/__spack_path_placeholder__/__spack_path_placeholder__/__spack_path_placeholder__/*/mucol*/setup.sh
fi

cd ${CODE}

#
# MyBIBUtils
#
echo "Building MyBIBUtils ..."
mkdir -p MyBIBUtils/build
cd MyBIBUtils/build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j${JOBS}
cd ${CODE}

#
# LCContent
# NB: run cmake from inside build/, because Pandora's cmake macros
#     write LCContentLibDeps.cmake into the current directory
#
echo "Building LCContent ..."
PANDORA_CMAKE_MODULES=$(ls -d /opt/spack/opt/spack/*/*/*/*/*/pandorapfa-*/cmakemodules)
mkdir -p LCContent/build
cd LCContent/build
cmake .. \
    -DCMAKE_MODULE_PATH=${PANDORA_CMAKE_MODULES} \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_CXX_STANDARD=20 \
    -DCMAKE_CXX_FLAGS=-Wno-error \
    -DCMAKE_INSTALL_PREFIX=${CODE}/LCContent/install
make -j${JOBS} install
cd ${CODE}

echo "Done. Built MyBIBUtils and LCContent in ${CODE}"
