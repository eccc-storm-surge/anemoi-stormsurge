#!/bin/bash

#PBS -N anemoi.dataset.ssh.allyears
#PBS -l select=1:ncpus=120:mem=600gb
#PBS -l walltime=06:00:00
#PBS -o /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/surge_ssh_allyears.out
#PBS -e /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/surge_ssh_allyears.err
#PBS -W umask=0022

set -x

WORKDIR=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match
TEMPLATE=${WORKDIR}/surge_ssh_config_allyear_template.yaml
CONFIG_DIR=${WORKDIR}/configs
ZARR_DIR=${WORKDIR}/ssh_zarr_data
LOGDIR=${WORKDIR}/anemoi_logs

START_YEAR=2004
END_YEAR=2025

mkdir -p "${CONFIG_DIR}" "${ZARR_DIR}" "${LOGDIR}"
export TMPDIR=${WORKDIR}/tmp
mkdir -p "${TMPDIR}"

. r.load.dot /fs/ssm/eccc/cmd/cmds/apps/pixi/pixi_0.75.0_all
cd "${WORKDIR}"

SCRIPT_START=$(date +%s)
echo "=== Script started at $(date) ==="

for (( YEAR=START_YEAR; YEAR<=END_YEAR; YEAR++ )); do
    NEXT_YEAR=$((YEAR + 1))
    YEAR_START_TIME=$(date +%s)

    CONFIG=${CONFIG_DIR}/surge_ssh_config_${YEAR}.yaml
    ZARR=${ZARR_DIR}/SSH_y${YEAR}_anemoi.zarr
    INIT_LOG=${LOGDIR}/ssh_init_${YEAR}.log

    sed -e "s/YEAR_START/${YEAR}/g" \
        -e "s/NEXT_YEAR/${NEXT_YEAR}/g" \
        "${TEMPLATE}" > "${CONFIG}"

    echo "=== Building ${YEAR} -> ${ZARR} ==="

    pixi run --offline anemoi-datasets init "${CONFIG}" "${ZARR}" 2>&1 | tee "${INIT_LOG}"

    ngroups=$(grep -oP '\d+(?=\s*groups)' "${INIT_LOG}" | head -1 || true)
    if [[ -z "${ngroups}" || ! "${ngroups}" =~ ^[0-9]+$ ]]; then
        echo "ERROR: could not determine ngroups for ${YEAR}. Check ${INIT_LOG}." >&2
        exit 1
    fi

    echo "${YEAR}: ${ngroups} groups"

    for i in $(seq 1 "${ngroups}"); do
        echo "  Processing part ${i}/${ngroups} for ${YEAR}"
        pixi run --offline anemoi-datasets load "${ZARR}" --part "${i}/${ngroups}" &
        if (( i % 40 == 0 )); then
            wait
        fi
    done
    wait

    pixi run --offline anemoi-datasets finalise "${ZARR}"

    YEAR_END_TIME=$(date +%s)
    YEAR_ELAPSED=$((YEAR_END_TIME - YEAR_START_TIME))
    echo "=== Finished ${YEAR} in ${YEAR_ELAPSED}s ==="
done

SCRIPT_END=$(date +%s)
TOTAL_ELAPSED=$((SCRIPT_END - SCRIPT_START))
echo "=== Script finished at $(date) ==="
echo "=== Total elapsed time: ${TOTAL_ELAPSED}s ==="
