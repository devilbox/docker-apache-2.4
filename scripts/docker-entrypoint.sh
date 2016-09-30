#!/bin/sh -eu

run() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}

runsu() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}sudo ${_cmd}${_reset}\n" "${_user}"
	/usr/local/bin/gosu root sh -c "LANG=C LC_ALL=C ${_cmd}"
}


################################################################################
# MAIN ENTRY POINT
################################################################################


##
## Forward database port to 127.0.0.1 ?
##

if set | grep '^FORWARD_DB_PORT_TO_LOCALHOST=' >/dev/null 2>&1; then

	if [ "${FORWARD_DB_PORT_TO_LOCALHOST}" = "1" ]; then
		if ! set | grep '^DB_REMOTE_ADDR=' >/dev/null 2>&1; then
			echo >&2 "You have enabled to port-forward database port to 127.0.0.1."
			echo >&2 "\$DB_REMOTE_ADDR must be set for this to work."
			exit 1
		fi
		if ! set | grep '^DB_REMOTE_PORT=' >/dev/null 2>&1; then
			echo >&2 "You have enabled to port-forward database port to 127.0.0.1."
			echo >&2 "\$DB_REMOTE_PORT must be set for this to work."
			exit 1
		fi
		if ! set | grep '^LOCALHOST_PORT=' >/dev/null 2>&1; then
			echo >&2 "You have enabled to port-forward database port to 127.0.0.1."
			echo >&2 "\$LOCALHOST_PORT must be set for this to work."
			exit 1
		fi
		##
		## Start socat tunnel
		## bring remove mysql to localhost
		##
		## This allows to have 3306 on 127.0.0.1
		##
		runsu "/usr/bin/socat tcp-listen:${LOCALHOST_PORT},reuseaddr,fork tcp:$DB_REMOTE_ADDR:$DB_REMOTE_PORT &"

	fi
fi




##
## Start Apache
##
runsu "/usr/sbin/httpd -DFOREGROUND"
