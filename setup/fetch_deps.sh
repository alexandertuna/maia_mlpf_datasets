#!/usr/bin/env bash
set -eo pipefail

#
# Clone each dependency into CODE and check out its pinned commit.
# Run from anywhere; does not need the container.
#
# Usage:
#   ./setup/fetch_deps.sh
#   MAIA_MLPF_CODE=/some/other/dir ./setup/fetch_deps.sh
#

CODE=${MAIA_MLPF_CODE:-"/ceph/users/atuna/work/maia/maia_mlpf"}

#
# name, url, commit
#
DEPS=(
    # simulation/steer_baseline.py: the MAIA ddsim steering
    "mucoll-benchmarks   https://github.com/MuonColliderSoft/mucoll-benchmarks.git 31d5882835f46ab3d0bcac7b78fbea3e232dcf9d"
    # digi_reco_steer.py: the MAIA digitisation and reconstruction. Fork branch AddMCTruthLink adds
    # --doCaloTruthLinks. Move back to MuonColliderSoft/MAIAConfig once it is merged.
    "MAIAConfig          https://github.com/alexandertuna/MAIAConfig.git     6c09be2e1fa104d473a4af1f330c1d0d7d752b8c"
    # maia_muon_truth_links (jpata/particleflow#546): track ECAL entry, centroid cluster angles,
    # majority-energy targets, charge-flip flag. Move back to jpata/particleflow once it is merged.
    "particleflow        https://github.com/jmduarte/particleflow.git        e6797a040b6e7ee0180f830938ae149673710c1d"
    # EvtGen and k4Gen are not in the v3.2 container, so build_deps.sh builds them
    "EvtGen              https://gitlab.cern.ch/evtgen/evtgen.git            38c3c2134da0c8816f6ce048d17043362a20ce84"
    "k4Gen               https://github.com/HEP-FCC/k4Gen.git                468a6ef8fa5ae4c22b96dcf25caef1a5f57d2f91"
)

#
# HepPDT (needed by k4Gen) has no git repository, so fetch its release tarball
#
HEPPDT=HepPDT-2.06.01
HEPPDT_URL=https://lcgpackages.web.cern.ch/tarFiles/sources/${HEPPDT}.tar.gz
HEPPDT_SHA256=12a1b6ffdd626603fa3b4d70f44f6e95a36f8f3b6d4fd614bac14880467a2c2e

cd ${CODE}
for dep in "${DEPS[@]}"; do
    read -r NAME URL COMMIT <<< "${dep}"
    if [ -e ${NAME} ]; then
        echo "Error: ${CODE}/${NAME} already exists. Remove it first."
        exit 1
    fi
    echo "Fetching ${NAME} at ${COMMIT} ..."
    git clone --quiet ${URL} ${NAME}
    cd ${NAME}
    git -c advice.detachedHead=false checkout --quiet ${COMMIT}
    cd ..
done

if [ -e ${HEPPDT} ]; then
    echo "Error: ${CODE}/${HEPPDT} already exists. Remove it first."
    exit 1
fi
echo "Fetching ${HEPPDT} ..."
curl --silent --show-error --fail --location --output ${HEPPDT}.tar.gz ${HEPPDT_URL}
echo "${HEPPDT_SHA256}  ${HEPPDT}.tar.gz" | sha256sum --check --quiet
tar xzf ${HEPPDT}.tar.gz
rm ${HEPPDT}.tar.gz

echo "Done. Dependencies are in ${CODE}"
