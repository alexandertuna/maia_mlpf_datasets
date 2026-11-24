# maia_mlpf_datasets

Produce MLPF training datasets for the MAIA detector at a 10 TeV muon collider,
from a Pythia8 card to post-processed parquet files:

gen (k4Gen + Pythia8) → sim (ddsim) → digi + reco (k4run with MAIAConfig: tracking, calo, Pandora, truth links) → post-processing (particleflow)

All intermediate files after gen are EDM4hep.

Everything runs in the MuColl container:

```bash
/cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v3.2-amd64
```

## Setup

```bash
mkdir maia_mlpf && cd maia_mlpf
export MAIA_MLPF_CODE=$PWD
export MAIA_MLPF_REPO=$PWD/maia_mlpf_datasets
git clone https://github.com/alexandertuna/maia_mlpf_datasets.git
./maia_mlpf_datasets/setup/fetch_deps.sh
apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v3.2-amd64 ./maia_mlpf_datasets/setup/build_deps.sh
apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v3.2-amd64 ./maia_mlpf_datasets/setup/make_venv.sh
```

This puts the repo and its dependencies side by side:

```
maia_mlpf/
  maia_mlpf_datasets/  mucoll-benchmarks/  MAIAConfig/  particleflow/
  EvtGen/  HepPDT-2.06.01/  k4Gen/  install/
```

The setup scripts can be run from any directory. They find everything through these environment variables,
whose defaults point to Alex's area, so export them in every new shell:

| Variable | Default | Contents |
|---|---|---|
| `MAIA_MLPF_CODE` | `/ceph/users/atuna/work/maia/maia_mlpf` | dependencies |
| `MAIA_MLPF_REPO` | `/ceph/users/atuna/work/maia/maia_mlpf/maia_mlpf_datasets` | this repo |
| `MAIA_MLPF_VENV` | `${MAIA_MLPF_REPO}/venv` | post-processing venv |

## Dependencies

| Dependency | Used for |
|---|---|
| [mucoll-benchmarks](https://github.com/MuonColliderSoft/mucoll-benchmarks) | ddsim steering (`simulation/steer_baseline.py`) |
| [MAIAConfig](https://github.com/alexandertuna/MAIAConfig/tree/AddMCTruthLink) | digi + reco steering, plus `--doCaloTruthLinks` (calo hit and cluster → MCParticle links), until it is merged into [MuonColliderSoft/MAIAConfig](https://github.com/MuonColliderSoft/MAIAConfig) |
| [particleflow](https://github.com/jmduarte/particleflow) | post-processing to parquet |
| [HepPDT](https://lcgpackages.web.cern.ch/tarFiles/sources/), [EvtGen](https://gitlab.cern.ch/evtgen/evtgen), [k4Gen](https://github.com/HEP-FCC/k4Gen) | Pythia8 in Gaudi for gen; k4Gen is not in the v3.2 container, so `build_deps.sh` builds them into `install/` |

The MAIA_v0 geometry comes from the container's k4geo (`$k4geo_DIR`).
Pinned commits are in `setup/fetch_deps.sh`.

## Running

One job (10 events) for one seed, from the directory where outputs should go:

```bash
apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v3.2-amd64 ${MAIA_MLPF_REPO}/scripts/go.sh 100000
```

Steps can be switched off with `DO_GEN`, `DO_SIM`, `DO_REC`, `DO_POST`, `DO_CLEANUP` (default `true`),
e.g. `DO_GEN=false DO_SIM=false` to re-run reco on an existing `ttbar_sim_100000.edm4hep.root`.
Sim takes about 25 minutes per event; digi + reco about 1 minute per event.

Post-processing does not yet support the v3.2 reco output, so use `DO_POST=false` for now.

Many jobs on condor (seeds 100000-100099), submitted from `condor/`:

```bash
cd ${MAIA_MLPF_REPO}/condor
mkdir -p logs
condor_submit go_one_event.sub
```

Merge the per-job parquet files into one file:

```bash
apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v3.2-amd64 \
  ${MAIA_MLPF_REPO}/venv/bin/python ${MAIA_MLPF_REPO}/scripts/merge_parquet_files.py DIRECTORY_OF_PARQUET_FILES/ merged.parquet
```

## Layout

- `config/gen`: Pythia8 card and k4Gen steering
- `scripts/`: `go.sh` (one job) and `merge_parquet_files.py`
- `condor/`: submit file
- `setup/`: fetch, build, and venv scripts
