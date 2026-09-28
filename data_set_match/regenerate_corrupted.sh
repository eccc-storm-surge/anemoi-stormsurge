#!/bin/bash

. r.load.dot  /fs/ssm/eccc/cmd/cmds/ext/20260508

set -e   # stop immediately if any command fails

DATA_BASE=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge
FIXED_BASE=${DATA_BASE}/time_fixed
LATLON_SOURCE=${DATA_BASE}/training_data_surge_PN/PN_y1957.nc

BROKEN_FILES=(
    "UU 2023" "UU 2024" "UU 2025"
    "VV 2023" "VV 2024" "VV 2025"
)

for ENTRY in "${BROKEN_FILES[@]}"; do
    read -r VAR YEAR <<< "${ENTRY}"
    DIR=training_data_surge_${VAR}

    IN_FILE=${DATA_BASE}/${DIR}/${VAR}_y${YEAR}.nc
    OUT_FILE=${FIXED_BASE}/${DIR}/${VAR}_y${YEAR}.nc

    echo "=== Regenerating ${VAR} ${YEAR} ==="

    # Remove the corrupted file first (safer than letting cdo overwrite
    # a possibly-locked/half-written file in place)
    rm -f "${OUT_FILE}"

    echo "Step 1: fixing time axis..."
    cdo -f nc setcalendar,standard -settaxis,${YEAR}-01-01,00:00:00,1hour \
        "${IN_FILE}" "${OUT_FILE}"

    echo "Step 2: appending lat/lon..."
    ncks -A -v longitude,latitude "${LATLON_SOURCE}" "${OUT_FILE}"


    echo "Step 3: verifying..."
    VERIFY_FILE=${DATA_BASE}/data_set_match/verify_${VAR}_${YEAR}.txt
    if ncdump -h "${OUT_FILE}" > ${VERIFY_FILE} 2>&1; then
        if grep -q "^}" ${VERIFY_FILE}; then
            echo "${VAR} ${YEAR}: OK - file is readable and complete"
        else
            echo "${VAR} ${YEAR}: WARNING - ncdump succeeded but output looks incomplete, check manually"
        fi
    else
        echo "${VAR} ${YEAR}: FAILED - still cannot read file, see error:"
        cat ${VERIFY_FILE}
    fi
    rm -f ${VERIFY_FILE}

    echo ""
done

echo "Done regenerating all flagged files."