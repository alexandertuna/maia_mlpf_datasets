# maia_mlpf_datasets

Produce MLPF training datasets for the MAIA detector at a 10 TeV muon collider,
from a Pythia8 card to post-processed parquet files:

gen (Pythia8) → sim (ddsim) → reco (k4run: tracking, calo, Pandora) → lcio2edm4hep → post-processing (particleflow)

Everything runs in the MuColl container:

```bash
/cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v2.9.8-amd64
```

## Setup

```bash
mkdir maia_mlpf && cd maia_mlpf
export MAIA_MLPF_CODE=$PWD
export MAIA_MLPF_REPO=$PWD/maia_mlpf_datasets
git clone https://github.com/alexandertuna/maia_mlpf_datasets.git
./maia_mlpf_datasets/setup/fetch_deps.sh
apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v2.9.8-amd64 ./maia_mlpf_datasets/setup/build_deps.sh
apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v2.9.8-amd64 ./maia_mlpf_datasets/setup/make_venv.sh
```

This puts the repo and its dependencies side by side:

```
maia_mlpf/
  maia_mlpf_datasets/  detector-simulation/  LCContent/  MyBIBUtils/  particleflow/
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
| [detector-simulation](https://github.com/madbaron/detector-simulation) | MAIA_v0 geometry |
| [MyBIBUtils](https://github.com/madbaron/MyBIBUtils) | Marlin processors and calorimeter thresholds |
| [LCContent](https://github.com/alexandertuna/LCContent/tree/v03-01-06-jmduarte-muon-coil-midpoint) | Pandora algorithms, v03-01-06 plus a muon reconstruction fix ([PandoraPFAOrg/LCContent#53](https://github.com/PandoraPFAOrg/LCContent/pull/53)) |
| [particleflow](https://github.com/jpata/particleflow) | post-processing to parquet |

Pinned commits are in `setup/fetch_deps.sh`.

## Running

One job (10 events) for one seed, from the directory where outputs should go:

```bash
apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v2.9.8-amd64 ${MAIA_MLPF_REPO}/scripts/go.sh 100000
```

Steps can be switched off with `DO_GEN`, `DO_SIM`, `DO_REC`, `DO_POST`, `DO_CLEANUP` (default `true`),
e.g. `DO_GEN=false DO_SIM=false` to re-run reco on an existing `ttbar_sim_100000.slcio`.

Many jobs on condor (seeds 100000-100099), submitted from `condor/`:

```bash
cd ${MAIA_MLPF_REPO}/condor
mkdir -p logs
condor_submit go_one_event.sub
```

Merge the per-job parquet files into one file:

```bash
apptainer exec /cvmfs/unpacked.cern.ch/ghcr.io/muoncollidersoft/mucoll-sim-ubuntu24:v2.9.8-amd64 \
  ${MAIA_MLPF_REPO}/venv/bin/python ${MAIA_MLPF_REPO}/scripts/merge_parquet_files.py DIRECTORY_OF_PARQUET_FILES/ merged.parquet
```

## Layout

- `config/gen`, `config/sim`, `config/reco`: Pythia8 card, ddsim steering, reco steering and Pandora settings
- `scripts/`: `go.sh` (one job) and `merge_parquet_files.py`
- `condor/`: submit file
- `setup/`: fetch, build, and venv scripts
