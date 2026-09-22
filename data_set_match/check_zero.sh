#!/bin/bash

#PBS -N cdo.date.check
#PBS -l select=1:ncpus=2:mem=8gb
#PBS -l walltime=05:00:00
#PBS -o /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/date_check.out
#PBS -e /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/date_check.err

. r.load.dot /fs/ssm/eccc/cmd/cmds/apps/pixi/202607/00/pixi_0.75.0_all

export PATH=/fs/ssm/eccc/cmd/cmds/ext/20260508/rhel-9-graniterapids-64/bin:$PATH
export LD_LIBRARY_PATH=/lib64:/fs/ssm/eccc/cmd/cmds/ext/20260508/rhel-9-graniterapids-64/lib:/fs/ssm/eccc/cmd/cmds/ext/20260508/rhel-9-amd64-64/lib:$LD_LIBRARY_PATH

DATA_BASE=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge

BASE=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match
LOGDIR=${BASE}/cdo_check_logs
REPORT=${LOGDIR}/date_check_report.txt
FLAGGED=${LOGDIR}/date_check_flagged_only.txt

mkdir -p ${LOGDIR}
> ${REPORT}
> ${FLAGGED}

START_YEAR=1957
END_YEAR=2025

declare -A VAR_DIRS=(
    [UU]="training_data_surge_UU"
    [VV]="training_data_surge_VV"
    [PN]="training_data_surge_PN"
)

echo "Date check report - generated $(date)" >> ${REPORT}
echo "Checking for 0000-00-00 placeholder dates in every timestep" >> ${REPORT}
echo "========================================================" >> ${REPORT}
echo "" >> ${REPORT}

for VAR in UU VV PN; do
    DIR=${VAR_DIRS[$VAR]}
    for (( YEAR=START_YEAR; YEAR<=END_YEAR; YEAR++ )); do
        FILE=${DATA_BASE}/${DIR}/${VAR}_y${YEAR}.nc
        LOGFILE=${LOGDIR}/${VAR}_${YEAR}_full.log

        if [ ! -f "${FILE}" ]; then
            LINE="${VAR} ${YEAR}: MISSING FILE (${FILE})"
            echo "${LINE}" >> ${REPORT}
            echo "${LINE}" >> ${FLAGGED}
            continue
        fi

        echo "Checking ${VAR} ${YEAR} (full file, all timesteps)..."

        cdo -s infon "${FILE}" > "${LOGFILE}" 2>&1

        TOTAL_LINES=$(grep -c ":" "${LOGFILE}")
        BAD_COUNT=$(grep -c "0000-00-00" "${LOGFILE}")

        if [ "${BAD_COUNT}" -gt 0 ]; then
            LINE="${VAR} ${YEAR}: FAIL - ${BAD_COUNT} / ${TOTAL_LINES} timesteps have 0000-00-00"
            echo "${LINE}" >> ${FLAGGED}
        else
            LINE="${VAR} ${YEAR}: OK - 0 / ${TOTAL_LINES} timesteps have 0000-00-00"
        fi

        echo "${LINE}" >> ${REPORT}
    done
    echo "" >> ${REPORT}
done

echo "" >> ${REPORT}
echo "========================================================" >> ${REPORT}
echo "Done. Full report: ${REPORT}"                              >> ${REPORT}
echo "Flagged-only (problems) list: ${FLAGGED}"                  >> ${REPORT}