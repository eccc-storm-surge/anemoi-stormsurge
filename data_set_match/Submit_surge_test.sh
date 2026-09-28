#!/bin/bash

#PBS -N anemoi.dataset.surge.test
#PBS -l select=1:ncpus=120:mem=300gb
#PBS -l walltime=06:00:00
#PBS -o /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/surge_test.out
#PBS -e /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/surge_test.err
#PBS -W umask=0022

set -x

WORKDIR=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match
CONFIG=${WORKDIR}/Surge_wind_pressure_config_test.yaml
ZARR=${WORKDIR}/surge-wind-pressure-2002-test.zarr

export TMPDIR=${WORKDIR}/tmp
mkdir -p ${TMPDIR}

. r.load.dot /fs/ssm/eccc/cmd/cmds/apps/pixi/202607/00/pixi_0.75.0_all
cd ${WORKDIR}

#pixi run --offline anemoi-datasets init ${CONFIG} ${ZARR} --overwrite

#ngroups=176 88  # one year of data is much smaller - fewer parts needed

ngroups=$(pixi run --offline anemoi-datasets init ${CONFIG} ${ZARR} --overwrite 2>&1 | \
awk '/Dates: Found .* in [0-9]+ groups:/ {print $(NF-1); exit}')

echo "Number of groups: ${ngroups}"


for i in $(seq 1 ${ngroups}); do
    echo "Processing part ${i}/${ngroups}"
    pixi run --offline anemoi-datasets load ${ZARR} --part ${i}/${ngroups} & 
    if (( i % 20 == 0 )); then
        wait
    fi
done
wait

pixi run --offline anemoi-datasets finalise ${ZARR}