#!/bin/bash

# ---------------------------------------------------------------------------
# Title             : livejasmin-record.sh
# Description       : Automatically records model passed, when online
# Author            : dirk362
# Date              : 20170831
# Version           : 0.1
# Usage             : bash livejasmin-record.sh ModelName
# Notes             : ModelName must match exactly (including case) website
#                   : Called by livejasmin-parse.sh for automated processing
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

# $1 = channel name - and it *MUST* be case correct to match website

# init core variables
site_name=livejasmin
base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# define colours
c_error=$'\e[1;31m'    # red
c_model=$'\e[1;36m'    # cyan
c_debug=$'\e[1;33m'    # yellow
c_info=$'\e[0;37m'     # grey
c_reset=$'\e[0m'       # reset

# define passed parameter as channel (model)
if [[ ! $1 ]] ; then 
	printf "%s\n" "${c_error}DEBUG: Missing mandatory parameter(s). Exiting...${c_reset}"
	exit 1
else
	channel=$1
fi

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
model_online=0

# validate elements
for check_file in "${get_cmd}"
do
	if [[ ! -f ${check_file} ]] ; then
		printf "%s\n" "${c_error}DEBUG: Failed to locate required file - missing ${check_file##*/} - exiting...${c_reset}"
		exit 1
	fi
done

wget_base="--no-check-certificate --timeout=5 --tries=2 --no-proxy --no-verbose --quiet --user-agent=\"${user_agent}\""
wget_options=""

while [[ 1 ]]
do
	while [[ 1 ]]
	do
		while [[ ${model_online} -ne 1 ]]
		do
			chk_tmp=$(mktemp)
			chk_url="${model_url}${channel}?_dc=$(date +%s%3N)"
			${get_cmd} ${wget_base} ${wget_options} --referer ${site_url} "${chk_url}" --output-document="${chk_tmp}" 2>/dev/null
			if [[ -s "${chk_tmp}" ]] ; then
				proxy_address=$(cat "${chk_tmp}" | grep -o -P "(?<=proxy_ip\"\:\"https\:\\\/\\\/).*?(?=\")")
				if [[ ! "${proxy_address}" == "" ]] ; then
					model_online=1
					break
				fi
			fi
			rm "${chk_tmp}" 2>/dev/null
			sleep ${stream_timer}m 2>/dev/null
		done

		rm "${chk_tmp}" 2>/dev/null
		streampath="https://${proxy_address}/${channel}"

		output_dir="${recording_dir}/${site_name}/${channel}"
		if [[ ! -d "${output_dir%/#}" ]] ; then mkdir -p "${output_dir%/#}" ; fi
		opt_fn="${long_site_name}-${channel}-$(date ${date_format}).${fs_type}"
		filesave="${output_dir}/${opt_fn}"
		${get_cmd} "${streampath}" ${wget_base} ${wget_options} --output-document="${filesave}" &>/dev/null &
		runpid=$!
		chkloop=0
		sleep 10s 2>/dev/null
		if [[ -s "${filesave}" ]] ; then 
			printf "%s\n" "${c_info}[$(date +%x) - $(date +%X)]${c_reset} Model ${c_model}${channel}${c_reset} is online - recording..."
			break
		else
			sleep ${stream_timer}m 2>/dev/null
		fi
		# if got here somehow and still have a non-zero file, need to break loop as something is recording
		if [[ -s "${filesave}" ]] ; then break ; fi
		# if got here, then kill whatever might be running and restart
		{ kill ${runpid} && wait ${runpid}; } 2>/dev/null
		if [[ -f "${filesave}" ]] ; then find "${filesave}" -size 0 -delete 2>/dev/null ; fi
	done
	
	while [[ 1 ]]
	do	
		let chkloop++
		if [[ $(ps -U ${run_user} ux | awk '{print $2}' | grep -q ${runpid} 2>/dev/null) ]]; then
			if [[ -f "${filesave}" ]] ; then find "${filesave}" -size -${min_file_size} -delete 2>/dev/null ; fi
			printf "%s\n" "${c_info}[$(date +%x) - $(date +%X)]${c_reset} Model ${c_model}${channel}${c_reset} is now offline or in private."
			sleep 15s 2>/dev/null
			model_online=0
			break
		fi
		if [[ ${chkloop} -gt 6 ]] && [[ ! -s "${filesave}" ]] ; then
			{ kill ${runpid} && wait ${runpid}; } 2>/dev/null
			if [[ -f "${filesave}" ]] ; then find "${filesave}" -size -${min_file_size} -delete 2>/dev/null ; fi
			printf "%s\n" "${c_info}[$(date +%x) - $(date +%X)]${c_reset} Model ${c_model}${channel}${c_reset} is now offline or in private."
			sleep 15s 2>/dev/null
			chkloop=0
			model_online=0
			break
		fi
		if [[ -f "${filesave}" ]] ; then chk_filesize_1=$(ls -l "${filesave}" | awk '{ print $5 }') ; fi
		sleep 15s 2>/dev/null
		if [[ -f "${filesave}" ]] ; then chk_filesize_2=$(ls -l "${filesave}" | awk '{ print $5 }') ; fi
		if [[ ${chk_filesize_1} -eq ${chk_filesize_2} ]]; then
			# file is not increasing in size - assume bad stream and restart (and delete small files)
			{ kill ${runpid} && wait ${runpid}; } 2>/dev/null
			if [[ -f "${filesave}" ]] ; then find "${filesave}" -size -${min_file_size} -delete 2>/dev/null ; fi
			printf "%s\n" "${c_info}[$(date +%x) - $(date +%X)]${c_reset} Model ${c_model}${channel}${c_reset} is now offline or in private."
			sleep 15s 2>/dev/null
			chkloop=0
			model_online=0
			break
		fi
		sleep 15s 2>/dev/null
	done
done
exit 0
