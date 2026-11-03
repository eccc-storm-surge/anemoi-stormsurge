#!/bin/bash
#PBS -N anemoi.bathymetry.from.netcdf
#PBS -l select=1:ncpus=120:mem=300gb
#PBS -l walltime=06:00:00
#PBS -W umask=0022
#PBS -o /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/bathymetry_conversion_from_netcdf.out
#PBS -e /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/bathymetry_conversion_from_netcdf.err

PROJECT_ROOT=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge
WORKDIR="${PROJECT_ROOT}/data_set_match"
CONFIG="${WORKDIR}/bathymetry_conversion_from_netcdf.yaml"
OUTPUT="${WORKDIR}/bathymetry_and_mask_era5_grid_hourly_1993-2024.zarr"

. r.load.dot /fs/ssm/eccc/cmd/cmds/apps/pixi/202607/00/pixi_0.75.0_all
set -euo pipefail

export TMPDIR="${WORKDIR}/tmp"
mkdir -p "${TMPDIR}"
cd "${PROJECT_ROOT}"

overwrite_args=()
if [[ "${OVERWRITE:-0}" == 1 ]]; then
    overwrite_args+=(--overwrite)
elif [[ -e "${OUTPUT}" ]]; then
    printf 'Output already exists; refusing to overwrite. Set OVERWRITE=1 to rebuild.\n' >&2
    exit 1
fi

pixi run --offline anemoi-datasets create \
    "${CONFIG}" \
    "${OUTPUT}" \
    "${overwrite_args[@]}" \
    --processes 30
