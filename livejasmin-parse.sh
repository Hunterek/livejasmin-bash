#!/bin/bash

# ---------------------------------------------------------------------------
# Title             : livejasmin-parse.sh
# Description       : This script parses a text file to start sub-processes
# Author            : dirk362
# Date              : 20170831
# Version           : 0.2
# Usage             : bash livejasmin-parse.sh
# Notes             : reads livejasmin-models.txt as input file
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
script_exec="${base_dir}/${site_name}-record.sh"

# define colours
c_error=$'\e[1;31m'    # red
c_model=$'\e[1;36m'    # cyan
c_debug=$'\e[1;33m'    # yellow
c_info=$'\e[0;37m'     # grey
c_reset=$'\e[0m'       # reset

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

# validate elements
for check_file in "${models}" "${script_exec}"
do
	if [[ ! -f ${check_file} ]] ; then
		printf "%s\n" "${c_error}DEBUG: Failed to locate required file - missing ${check_file##*/} - exiting...${c_reset}"
		exit 1
	fi
done
if [[ ! ${parse_timer} = *[[:digit:]]* ]] ; then
	printf "%s\n" "${c_error}DEBUG: Timer was not a number - exiting...${c_reset}"
	exit 1
fi
if [[ ${parse_timer} -gt 10 ]] ; then
	printf "%s\n" "${c_debug}DEBUG: Timer was too long. Resetting to 10 minutes${c_reset}"
	parse_timer=10
fi

# outer loop which runs forever, with sleep timer between loops 
while [ 1 ]
do
	if [[ ! -d "${temp_dir%/#}" ]] ; then mkdir -p "${temp_dir%/#}" ; fi
	readarray -t this_run_array < "${models}"
	if [[ -z "${this_run_array}" ]] ; then
		printf "%s\n" "${c_error}DEBUG: Models file is empty - exiting...${c_reset}"
		exit 1
	fi
	if [[ -z "${saved_run_array}" ]] ; then
		# first run so force start all entries
		for init_run in ${this_run_array[@]} ; do
			if [[ -f "${temp_dir}/${init_run}.txt" ]] ; then continue ; fi
			printf "%s\n" "${c_info}[$(date +%x) - $(date +%X)]${c_reset} Added ${c_model}${init_run}${c_reset} to models to record"
			touch "${temp_dir}/${init_run}.txt"
			${base_dir}/${site_name}-record.sh ${init_run} &
		done
		saved_run_array=( "${this_run_array[@]}" )
	fi
	diff_array=($(echo ${this_run_array[@]} ${saved_run_array[@]} | tr ' ' '\n' | sort | uniq -u))
	if [[ ! "${diff_array}[@]" == "" ]] ; then
		for checkmodel in ${diff_array[@]} ; do
			printf "%s\n" "${c_info}[$(date +%x) - $(date +%X)]${c_reset} Processing difference in this run for ${c_model}${checkmodel}${c_reset}"
			if [[ -f "${temp_dir}/${checkmodel}.txt" ]] ; then
				# assume delete as different to last run and temporary file exists
				printf "%s\n" "${c_info}[$(date +%x) - $(date +%X)]${c_reset} Removed ${c_model}${checkmodel}${c_reset} from models to record"
				pid1=$(ps -U ${run_user} ux | grep -i ${site_chk}-record | grep -i ${checkmodel} | awk '{print $2}')
				pid2=$(ps -U ${run_user} ux | grep -i ${record_cmd} | grep -i ${checkmodel} | awk '{print $2}')
				{ kill ${pid1} ${pid2} && wait ${pid1} ${pid2}; } 2>/dev/null
				rm "${temp_dir}/${checkmodel}.txt" 2>/dev/null
			else
				# assume add as no temporary file exists
				printf "%s\n" "${c_info}[$(date +%x) - $(date +%X)]${c_reset} Added ${c_model}${checkmodel}${c_reset} to models to record"
				touch "${temp_dir}/${checkmodel}.txt"
				${base_dir}/${site_name}-record.sh ${checkmodel} &
			fi
		done
	fi
	saved_run_array=( "${this_run_array[@]}" )
	printf "%s\n" "${c_info}[$(date +%x) - $(date +%X)]${c_reset} Done, will re-scan ${models} in ${parse_timer} minutes"
	sleep ${parse_timer}m 2>/dev/null
done

exit 0
