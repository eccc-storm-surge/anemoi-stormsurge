#!/bin/bash

# Builds a unified view of UU/VV/PN data for 1993-2025, using symlinks
# (not copies, to avoid disk quota issues) so that:
#   - years that were flagged (broken time axis) point to the FIXED
#     version in time_fixed/
#   - years that were already correct point to the ORIGINAL file
#
# This gives you one consistent folder per variable covering the full
# 1993-2025 range without duplicating any data on disk.

DATA_BASE=/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge
FIXED_BASE=${DATA_BASE}/time_fixed
COMBINED_BASE=${DATA_BASE}/combined_1993_2025

START_YEAR=1993
END_YEAR=2025

declare -A VAR_DIRS=(
    [UU]="training_data_surge_UU"
    [VV]="training_data_surge_VV"
    [PN]="training_data_surge_PN"
)

# Years that were flagged (broken time axis) per variable - these years
# use the fixed version. Everything else in the range uses the original.
declare -A FLAGGED_YEARS
FLAGGED_YEARS[UU]="1993 1994 1995 1996 1997 2001 2004 2005 2006 2007 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2023 2024 2025"
FLAGGED_YEARS[VV]="1993 1994 1995 1996 1997 2001 2004 2005 2006 2007 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2023 2024 2025"
FLAGGED_YEARS[PN]="2019 2020"

for VAR in UU VV PN; do
    DIR=${VAR_DIRS[$VAR]}
    OUT_DIR=${COMBINED_BASE}/${DIR}
    mkdir -p ${OUT_DIR}

    declare -A IS_FLAGGED
    for Y in ${FLAGGED_YEARS[$VAR]}; do
        IS_FLAGGED[$Y]=1
    done

    for (( YEAR=START_YEAR; YEAR<=END_YEAR; YEAR++ )); do
        FILENAME=${VAR}_y${YEAR}.nc
        LINK_TARGET_PATH=${OUT_DIR}/${FILENAME}

        if [ -n "${IS_FLAGGED[$YEAR]}" ]; then
            SOURCE=${FIXED_BASE}/${DIR}/${FILENAME}
        else
            SOURCE=${DATA_BASE}/${DIR}/${FILENAME}
        fi

        if [ ! -f "${SOURCE}" ]; then
            echo "WARNING: ${VAR} ${YEAR} - source not found (${SOURCE}), skipping"
            continue
        fi

        # -f forces overwrite if the symlink already exists
        ln -sf "${SOURCE}" "${LINK_TARGET_PATH}"
        echo "${VAR} ${YEAR}: linked -> ${SOURCE}"
    done

    unset IS_FLAGGED
done

echo ""
echo "Done. Combined view (symlinks) is at: ${COMBINED_BASE}"