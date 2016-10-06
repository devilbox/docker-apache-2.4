#!/bin/sh -eu

##
## Variables
##
#HTTPD_CUSTOM_CONFIG="/etc/httpd/conf.d/defaults.conf"



##
## Functions
##

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
## Adjust timezone
##
if set | grep '^TIMEZONE='  >/dev/null 2>&1; then
	if [ -f "/usr/share/zoneinfo/${TIMEZONE}" ]; then
		runsu "rm /etc/localtime"
		runsu "ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
		runsu "date"
	else
		echo >&2 "Invalid timezone for \$TIMEZONE."
		echo >&2 "\$TIMEZONE: '${TIMEZONE}' does not exist."
		exit 1
	fi
fi



##
## Add new Apache configuration dir
##
if set | grep '^CUSTOM_HTTPD_CONF_DIR='  >/dev/null 2>&1; then
	# Tell apache to also look into this custom dir for configuratoin
	runsu "echo 'IncludeOptional ${CUSTOM_HTTPD_CONF_DIR}/*.conf' >> /etc/httpd/conf/httpd.conf"
fi



##
## Start Apache
##
runsu "hostname -I"
runsu "/usr/sbin/httpd -v 2>&1 | head -1"
runsu "/usr/sbin/httpd -DFOREGROUND"
