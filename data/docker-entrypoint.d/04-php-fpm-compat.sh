#!/usr/bin/env bash

set -e
set -u
set -o pipefail


############################################################
# Functions
############################################################

###
### Ensure COMPAT is set
###
export_php_fpm_compat() {
	local varname="${1}"
	local debug="${2}"
	local value="0"

	if ! env_set "${varname}"; then
		log "info" "\$${varname} not set. Not enabling PHP 5.2 compatibility mode." "${debug}"
		# Ensure variable is exported
		eval "export ${varname}=0"
	else
		value="$( env_get "${varname}" )"
		if [ "${value}" = "5.2" ]; then
			log "info" "PHP 5.2 compatibility mode: Enabled" "${debug}"
			# Ensure variable is exported
			eval "export ${varname}=1"
		else
			log "info" "PHP 5.2 compatibility mode: Disabled" "${debug}"
			# Ensure variable is exported
			eval "export ${varname}=0"
		fi
	fi
}
