#!/usr/bin/env bash
set -eo pipefail

#
# 1. set up environment before running
# NB: set up this environment from within the container!
# export PYTHONPATH=""
# python -m venv ./venv
# ./venv/bin/python -m pip -q install --upgrade pip
# ./venv/bin/python -m pip -q install awkward fastjet numpy tqdm uproot vector scipy pydantic comet_ml pyyaml pyarrow numba
#

#
# 2a. and activate container like this when running locally
# apptainer run /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v3.2-amd64
# source /opt/setup_mucoll.sh
#
# 2b. alternatively, you can run locally like:
# apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v3.2-amd64 ./go.sh 100000
#

#
# command line args
#
if [ -z "$1" ]; then
    echo "Usage: $0 SEED"
    exit 1
fi
SEED=${1}
REPO=${MAIA_MLPF_REPO:-"/ceph/users/atuna/work/maia/maia_mlpf/maia_mlpf_datasets"}
EVENTS_PER_JOB=10

#
# steering
#
DO_GEN=${DO_GEN:-true}
DO_SIM=${DO_SIM:-true}
DO_REC=${DO_REC:-true}
DO_POST=${DO_POST:-true}
DO_CLEANUP=${DO_CLEANUP:-true}

#
# paths
#
CODE=${MAIA_MLPF_CODE:-"/ceph/users/atuna/work/maia/maia_mlpf"}
VENV=${MAIA_MLPF_VENV:-"${REPO}/venv"}
PFLOW=${CODE}/particleflow

#
# setup if necessary
#
if ! command -v ddsim >/dev/null 2>&1; then
    echo "Setting env ${SEED} at $(date) ..."
    source /opt/setup_mucoll.sh
fi
export LD_LIBRARY_PATH=${CODE}/install/lib:${LD_LIBRARY_PATH}
export PYTHONPATH=${CODE}/install/python:${PYTHONPATH}

#
# geometry from the container's k4geo (k4geo_DIR is set by the setup above)
#
COMPACT=${k4geo_DIR}/MuColl/MAIA/compact/MAIA_v0/MAIA_v0.xml

#
# file names
#
TYPEEVENT="ttbar"
GEN_TEMPLATE=p8_mumu_tt_ecm10000.cmd
GEN_CMD=p8_mumu_tt_ecm10000_${SEED}.cmd
GEN_HEPMC=${TYPEEVENT}_${SEED}.hepmc
SIM_STEER=${CODE}/mucoll-benchmarks/simulation/steer_baseline.py
SIM_EDM4HEP=${TYPEEVENT}_sim_${SEED}.edm4hep.root
REC_STEER=${CODE}/MAIAConfig/MAIAConfig/digi_reco_steer.py
REC_EDM4HEP=${TYPEEVENT}_reco_${SEED}.edm4hep.root
GEN_LOG=log_gen_${SEED}.txt
SIM_LOG=log_sim_${SEED}.txt
REC_LOG=log_rec_${SEED}.txt
POST_LOG=log_post_${SEED}.txt

#
# gen
#
if $DO_GEN; then
    echo "Running gen ${SEED} at $(date) ..."
    cp ${REPO}/config/gen/${GEN_TEMPLATE} ${GEN_CMD}
    sed -i s/12345/${SEED}/g ${GEN_CMD}
    k4run \
        ${REPO}/config/gen/pythia.py \
        --Dumper.Filename ${GEN_HEPMC} \
        --Pythia8.PythiaInterface.pythiacard ${GEN_CMD} \
        --RndmGenSvc.Engine.Seeds ${SEED} \
        &> ${GEN_LOG}
fi

#
# sim
#
if $DO_SIM; then
    echo "Running sim ${SEED} at $(date) ..."
    ddsim \
        --inputFile ${GEN_HEPMC} \
        --outputFile ${SIM_EDM4HEP} \
        --steeringFile ${SIM_STEER} \
        --compactFile ${COMPACT} \
        --numberOfEvents ${EVENTS_PER_JOB} \
        --random.seed ${SEED} \
        &> ${SIM_LOG}
fi

#
# rec
#
if $DO_REC; then
    echo "Running rec ${SEED} at $(date) ..."
    k4run ${REC_STEER} \
        --doCaloTruthLinks \
        --inputFiles ${SIM_EDM4HEP} \
        --outputFile ${REC_EDM4HEP} \
        -n ${EVENTS_PER_JOB} \
        &> ${REC_LOG}
fi

#
# postprocess
#
if $DO_POST; then
    echo "Running post-processing ${SEED} at $(date) ..."
    export PYTHONPATH=${PFLOW}
    ${VENV}/bin/python \
        ${PFLOW}/mlpf/data/key4hep/postprocessing.py \
        --input ${REC_EDM4HEP} \
        --outpath $(pwd) \
        --detector maia \
        &> ${POST_LOG}
fi

#
# cleanup
#
if $DO_CLEANUP; then
    echo "Running cleanup ${SEED} at $(date) ..."
    rm -f ${GEN_CMD} ${GEN_HEPMC} ${SIM_EDM4HEP} ${REC_EDM4HEP}
fi
