#!/bin/bash

#PBS -N anemoi.dataset.surge.allyears
#PBS -l select=1:ncpus=120:mem=600gb
#PBS -l walltime=06:00:00
#PBS -o /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/surge_allyear2nd.out
#PBS -e /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/surge_allyear2nd.err
#PBS -W umask=0022

set -x

WORKDIR=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match
TEMPLATE=${WORKDIR}/surge_atm_config_allyear_template.yaml
CONFIG_DIR=${WORKDIR}/configs
ZARR_DIR=${WORKDIR}/surge_atm_zarr_data_second_time
LOGDIR=${WORKDIR}/anemoi_logs

START_YEAR=2023
END_YEAR=2025

mkdir -p ${CONFIG_DIR}
mkdir -p ${ZARR_DIR}
mkdir -p ${LOGDIR}

export TMPDIR=${WORKDIR}/tmp
mkdir -p ${TMPDIR}

. r.load.dot /fs/ssm/eccc/cmd/cmds/apps/pixi/202607/00/pixi_0.75.0_all
cd ${WORKDIR}

SCRIPT_START=$(date +%s)
echo "=== Script started at $(date) ==="

for (( YEAR=START_YEAR; YEAR<=END_YEAR; YEAR++ )); do

    YEAR_START_TIME=$(date +%s)

    CONFIG=${CONFIG_DIR}/surge_atm_config_2nd${YEAR}.yaml
    ZARR=${ZARR_DIR}/surge_atm_2nd${YEAR}.zarr
    INIT_LOG=${LOGDIR}/init2nd_${YEAR}.log

    # Generate this year's config from the template
    sed "s/YEAR_START/${YEAR}/g" ${TEMPLATE} > ${CONFIG}

    echo "=== Building ${YEAR} -> ${ZARR} ==="

    pixi run --offline anemoi-datasets init ${CONFIG} ${ZARR} 2>&1 | tee ${INIT_LOG}

    ngroups=$(grep -oP '\d+(?=\s*groups)' ${INIT_LOG} | head -1)

    if [[ -z "${ngroups}" || ! "${ngroups}" =~ ^[0-9]+$ ]]; then
        echo "ERROR: could not determine ngroups for ${YEAR}. Check ${INIT_LOG}. Skipping this year."
        continue
    fi

    echo "${YEAR}: ${ngroups} groups"

    for i in $(seq 1 ${ngroups}); do
        echo "  Processing part ${i}/${ngroups} for ${YEAR}"
        pixi run --offline anemoi-datasets load ${ZARR} --part ${i}/${ngroups} &
        if (( i % 40 == 0 )); then
            wait
        fi
    done
    wait

    pixi run --offline anemoi-datasets finalise ${ZARR}

    YEAR_END_TIME=$(date +%s)
    YEAR_ELAPSED=$(( YEAR_END_TIME - YEAR_START_TIME ))
    echo "=== Finished ${YEAR} in ${YEAR_ELAPSED}s ($(( YEAR_ELAPSED / 60 ))m $(( YEAR_ELAPSED % 60 ))s) ==="

done

SCRIPT_END=$(date +%s)
TOTAL_ELAPSED=$(( SCRIPT_END - SCRIPT_START ))
echo "=== Script finished at $(date) ==="
echo "=== Total elapsed time: ${TOTAL_ELAPSED}s ($(( TOTAL_ELAPSED / 3600 ))h $(( (TOTAL_ELAPSED % 3600) / 60 ))m $(( TOTAL_ELAPSED % 60 ))s) ==="