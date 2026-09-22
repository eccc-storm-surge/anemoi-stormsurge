#!/bin/bash

#PBS -N ncks.add.latlon
#PBS -l select=1:ncpus=2:mem=8gb
#PBS -l walltime=02:00:00
#PBS -o /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/add_latlon.out
#PBS -e /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/add_latlon.err

. r.load.dot /fs/ssm/eccc/cmd/cmds/apps/pixi/202607/00/pixi_0.75.0_all
export PATH=/fs/ssm/eccc/cmd/cmds/ext/20260508/rhel-9-graniterapids-64/bin:$PATH
export LD_LIBRARY_PATH=/lib64:/fs/ssm/eccc/cmd/cmds/ext/20260508/rhel-9-graniterapids-64/lib:/fs/ssm/eccc/cmd/cmds/ext/20260508/rhel-9-amd64-64/lib:$LD_LIBRARY_PATH

# The cdo setcalendar/settaxis time-fix step stripped lat/lon coordinate
# variables from ALL fixed files (UU, VV, AND PN) - confirmed by comparing
# the original PN_y2024.nc (has proper latitude/longitude arrays) against
# the time-fixed PN_y2019.nc (only has time + msl, lat/lon gone).
#
# This appends real lat/lon back into every file in time_fixed/, for all
# three variables, using ncks -A (append - does NOT overwrite existing
# data) with a reference taken from an ORIGINAL (untouched) PN file.

DATA_BASE=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge
FIXED_BASE=${DATA_BASE}/time_fixed

# Reference file providing real lat/lon coordinate arrays - must be an
# ORIGINAL (non-time-fixed) PN file, since those still have proper lat/lon.
LATLON_SOURCE=${DATA_BASE}/training_data_surge_PN/PN_y1957.nc

LOGDIR=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/cdo_check_logs
LOG=${LOGDIR}/add_latlon_report.txt

mkdir -p ${LOGDIR}
> ${LOG}
echo "Add lat/lon report - generated $(date)" >> ${LOG}
echo "Source: ${LATLON_SOURCE}" >> ${LOG}
echo "==================================================" >> ${LOG}
echo "" >> ${LOG}

if [ ! -f "${LATLON_SOURCE}" ]; then
    echo "FATAL: reference source file not found: ${LATLON_SOURCE}" >> ${LOG}
    exit 1
fi

for VAR in UU VV PN; do
    DIR=${FIXED_BASE}/training_data_surge_${VAR}

    if [ ! -d "${DIR}" ]; then
        echo "${VAR}: SKIPPED - directory not found (${DIR})" >> ${LOG}
        continue
    fi

    for FILE in ${DIR}/${VAR}_y*.nc; do
        [ -e "${FILE}" ] || continue   # handles case of no matching files

        echo "Adding lat/lon to $(basename ${FILE})..."

        ncks -A -v longitude,latitude "${LATLON_SOURCE}" "${FILE}" 2>> ${LOG}

        if [ $? -eq 0 ]; then
            echo "$(basename ${FILE}): OK" >> ${LOG}
        else
            echo "$(basename ${FILE}): FAILED - see error above" >> ${LOG}
        fi
    done
done

echo "" >> ${LOG}
echo "==================================================" >> ${LOG}
echo "Done. Full report: ${LOG}" >> ${LOG}