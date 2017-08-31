#!/bin/bash

# ---------------------------------------------------------------------------
# Title             : process-livejasmin.sh
# Description       : Automatically shutdown all subprocesses and scripts
# Author            : dirk362
# Date              : 20170831
# Version           : 0.1
# Usage             : bash process-livejasmin.sh
# Notes             : Terminate all recordings and delete temporary files
# Bash_version      : 4.3.x
# Copyright (c)     : 2017 - https://github.com/dirk362
# ---------------------------------------------------------------------------
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.
# ---------------------------------------------------------------------------

# init core variables
site_name=livejasmin
base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
temp_dir="${base_dir}/${site_name}_temp"

# parse ini file
shopt -s extglob
while IFS='= ' read lhs rhs
do
if [[ ! ${lhs} =~ ^\ *# && -n ${lhs} ]] ; then
	rhs="${rhs%%\#*}"    # Del in line right comments
	rhs="${rhs%%*( )}"   # Del trailing spaces
	rhs="${rhs%\"*}"     # Del opening string quotes 
	rhs="${rhs#\"*}"     # Del closing string quotes
	declare ${lhs}="${rhs}"
fi
done < "${base_dir}/${site_name}.ini"
shopt -u extglob

run_user=$(whoami)
output_dir="${recording_dir}/${site_name}"
site_chk="[${site_name:0:1}]${site_name:1}"
run_chk=${get_cmd##*/}
run_chk="[${run_chk:0:1}]${run_chk:1}"

kill $(ps -U ${run_user} ux | grep -i ${site_chk}-parse | awk '{print $2}') &> /dev/null 2>&1
kill $(ps -U ${run_user} ux | grep -i ${site_chk}-record | awk '{print $2}') &> /dev/null 2>&1
kill $(ps -U ${run_user} ux | grep -i ${run_chk} | grep -i "${output_dir}/" | awk '{print $2}') &> /dev/null 2>&1
find ${temp_dir} -type f -name "*.txt" -delete 2>/dev/null
find ${output_dir} -name "*.${fs_type}" -size 0 -delete 2>/dev/null
find ${output_dir} -type d -empty -delete 2>/dev/null

exit 0
