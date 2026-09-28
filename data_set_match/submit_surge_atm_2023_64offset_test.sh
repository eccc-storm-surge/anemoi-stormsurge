#!/bin/bash

#PBS -N anemoi.dataset.2023.offset64test
#PBS -l select=1:ncpus=120:mem=600gb
#PBS -l walltime=02:00:00
#PBS -o /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/surge_2023_offset64test.out
#PBS -e /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/surge_2023_offset64test.err
#PBS -W umask=0022

set -x

WORKDIR=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match
CONFIG=${WORKDIR}/surge_atm_config_2023_offset64test.yaml
ZARR=${WORKDIR}/surge_atm_2023_offset64test.zarr

export TMPDIR=${WORKDIR}/tmp
mkdir -p ${TMPDIR}

. r.load.dot /fs/ssm/eccc/cmd/cmds/apps/pixi/202607/00/pixi_0.75.0_all
cd ${WORKDIR}

SCRIPT_START=$(date +%s)
echo "=== Started at $(date) ==="

ngroups=$(pixi run --offline anemoi-datasets init ${CONFIG} ${ZARR} 2>&1 | \
awk '/Dates: Found .* in [0-9]+ groups:/ {print $(NF-1); exit}')

echo "Number of groups: ${ngroups}"

if [[ -z "${ngroups}" ]]; then
    echo "ERROR: ngroups empty, aborting"
    exit 1
fi

for i in $(seq 1 ${ngroups}); do
    echo "Processing part ${i}/${ngroups}"
    pixi run --offline anemoi-datasets load ${ZARR} --part ${i}/${ngroups} &
    if (( i % 40 == 0 )); then
        wait
    fi
done
wait

pixi run --offline anemoi-datasets finalise ${ZARR}

SCRIPT_END=$(date +%s)
TOTAL_ELAPSED=$(( SCRIPT_END - SCRIPT_START ))
echo "=== Finished at $(date) ==="
echo "=== Total elapsed time: ${TOTAL_ELAPSED}s ($(( TOTAL_ELAPSED / 60 ))m $(( TOTAL_ELAPSED % 60 ))s) ==="