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
    "detector-simulation https://github.com/madbaron/detector-simulation.git 768b887ad650987a6b55b2d7c612ca50685d0e95"
    "MyBIBUtils          https://github.com/madbaron/MyBIBUtils.git          a4dfb0c6d9c714699a722f2320fb7d99a6da8cea"
    "LCContent           https://github.com/alexandertuna/LCContent.git      bb99f962db606eaa731070be8470a7a9d6f6485a"
    "particleflow        https://github.com/jpata/particleflow.git           522df76de76da1c36972d6bca79f361682092bde"
)

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

echo "Done. Dependencies are in ${CODE}"
