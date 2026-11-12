#!/usr/bin/env bash
set -eo pipefail

#
# Create the python venv used for post-processing.
# Only particleflow's mlpf/data/key4hep/postprocessing.py needs it.
# Run inside the container, e.g.:
#
#   apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v2.9.8-amd64 ./setup/make_venv.sh
#

REPO=${MAIA_MLPF_REPO:-"/ceph/users/atuna/work/maia/maia_mlpf/maia_mlpf_datasets"}
VENV=${MAIA_MLPF_VENV:-"${REPO}/venv"}

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

if [ -e ${VENV} ]; then
    echo "Error: ${VENV} already exists. Remove it first."
    exit 1
fi

#
# keep the container's python packages out of the venv
#
export PYTHONPATH=""

echo "Creating venv ${VENV} ..."
python -m venv ${VENV}
${VENV}/bin/python -m pip -q install --upgrade pip
${VENV}/bin/python -m pip -q install awkward fastjet numpy tqdm uproot vector scipy pydantic comet_ml pyyaml pyarrow numba

echo "Done. Created venv ${VENV}"
