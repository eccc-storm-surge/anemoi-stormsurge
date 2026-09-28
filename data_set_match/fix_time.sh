#!/bin/bash

#PBS -N cdo.fix.time
#PBS -l select=1:ncpus=2:mem=8gb
#PBS -l walltime=03:00:00
#PBS -o /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/fix_time.out
#PBS -e /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/anemoi_logs/fix_time.err

# Environment needed for cdo (same fix as the date-check job)
. r.load.dot /fs/ssm/eccc/cmd/cmds/apps/pixi/202607/00/pixi_0.75.0_all
export PATH=/fs/ssm/eccc/cmd/cmds/ext/20260508/rhel-9-graniterapids-64/bin:$PATH
export LD_LIBRARY_PATH=/lib64:/fs/ssm/eccc/cmd/cmds/ext/20260508/rhel-9-graniterapids-64/lib:/fs/ssm/eccc/cmd/cmds/ext/20260508/rhel-9-amd64-64/lib:$LD_LIBRARY_PATH

DATA_BASE=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge
FIXED_BASE=${DATA_BASE}/time_fixed

LOGDIR=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/data_set_match/cdo_check_logs
FIXLOG=${LOGDIR}/fix_time_report.txt

mkdir -p ${FIXED_BASE}/training_data_surge_UU
mkdir -p ${FIXED_BASE}/training_data_surge_VV
mkdir -p ${FIXED_BASE}/training_data_surge_PN
mkdir -p ${LOGDIR}

> ${FIXLOG}
echo "Time-fix report - generated $(date)" >> ${FIXLOG}
echo "==================================================" >> ${FIXLOG}
echo "" >> ${FIXLOG}

declare -A VAR_DIRS=(
    [UU]="training_data_surge_UU"
    [VV]="training_data_surge_VV"
    [PN]="training_data_surge_PN"
)

# Flagged files, filtered to the requested 1993-2025 range.
# Format: "VAR YEAR"
FLAGGED=(
"UU 1993" "UU 1994" "UU 1995" "UU 1996" "UU 1997" "UU 2001" "UU 2004"
"UU 2005" "UU 2006" "UU 2007" "UU 2009" "UU 2010" "UU 2011" "UU 2012"
"UU 2013" "UU 2014" "UU 2015" "UU 2016" "UU 2017" "UU 2018" "UU 2019"
"UU 2023" "UU 2024" "UU 2025"
"VV 1993" "VV 1994" "VV 1995" "VV 1996" "VV 1997" "VV 2001" "VV 2004"
"VV 2005" "VV 2006" "VV 2007" "VV 2009" "VV 2010" "VV 2011" "VV 2012"
"VV 2013" "VV 2014" "VV 2015" "VV 2016" "VV 2017" "VV 2018" "VV 2019"
"VV 2023" "VV 2024" "VV 2025"
"PN 2019" "PN 2020"
)

for ENTRY in "${FLAGGED[@]}"; do
    read -r VAR YEAR <<< "${ENTRY}"
    DIR=${VAR_DIRS[$VAR]}

    IN_FILE=${DATA_BASE}/${DIR}/${VAR}_y${YEAR}.nc
    OUT_FILE=${FIXED_BASE}/${DIR}/${VAR}_y${YEAR}.nc

    if [ ! -f "${IN_FILE}" ]; then
        echo "${VAR} ${YEAR}: SKIPPED - input file not found (${IN_FILE})" >> ${FIXLOG}
        continue
    fi

    echo "Fixing ${VAR} ${YEAR}..."

    cdo setcalendar,standard \
        -settaxis,${YEAR}-01-01,00:00:00,1hour \
        "${IN_FILE}" "${OUT_FILE}" 2>> ${FIXLOG}

    if [ $? -eq 0 ]; then
        echo "${VAR} ${YEAR}: OK - fixed file written to ${OUT_FILE}" >> ${FIXLOG}
    else
        echo "${VAR} ${YEAR}: FAILED - see error above" >> ${FIXLOG}
    fi
done

echo "" >> ${FIXLOG}
echo "==================================================" >> ${FIXLOG}
echo "Done. Fixed files are in: ${FIXED_BASE}" >> ${FIXLOG}
echo "Full report: ${FIXLOG}" >> ${FIXLOG}