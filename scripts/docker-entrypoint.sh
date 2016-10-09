#!/bin/sh -eu

###
### Variables
###
DEBUG_COMMANDS=0



###
### Functions
###
run() {
	_cmd="${1}"
	_debug="0"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"


	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		if [ "${2}" = "1" ]; then
			_debug="1"
		fi
	fi


	if [ "${DEBUG_COMMANDS}" = "1" ] || [ "${_debug}" = "1" ]; then
		printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	fi
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}

runsu() {
	_cmd="${1}"
	_debug="0"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		if [ "${2}" = "1" ]; then
			_debug="1"
		fi
	fi


	if [ "${DEBUG_COMMANDS}" = "1" ] || [ "${_debug}" = "1" ]; then
		printf "${_red}%s \$ ${_green}sudo ${_cmd}${_reset}\n" "${_user}"
	fi

	/usr/local/bin/gosu root sh -c "LANG=C LC_ALL=C ${_cmd}"
}


log() {
	_lvl="${1}"
	_msg="${2}"

	_clr_ok="\033[0;32m"
	_clr_info="\033[0;34m"
	_clr_warn="\033[0;33m"
	_clr_err="\033[0;31m"
	_clr_rst="\033[0m"

	if [ "${_lvl}" = "ok" ]; then
		printf "${_clr_ok}[OK]   %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "info" ]; then
		printf "${_clr_info}[INFO] %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "warn" ]; then
		printf "${_clr_warn}[WARN] %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	elif [ "${_lvl}" = "err" ]; then
		printf "${_clr_err}[ERR]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	else
		printf "${_clr_err}[???]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	fi
}



################################################################################
# BOOTSTRAP
################################################################################

if set | grep '^DEBUG_COMPOSE_ENTRYPOINT='  >/dev/null 2>&1; then
	if [ "${DEBUG_COMPOSE_ENTRYPOINT}" = "1" ]; then
		DEBUG_COMMANDS=1
	fi
fi


################################################################################
# MAIN ENTRY POINT
################################################################################

###
### Adjust timezone
###

if ! set | grep '^TIMEZONE='  >/dev/null 2>&1; then
	log "warn" "\$TIMEZONE not set."
else
	if [ -f "/usr/share/zoneinfo/${TIMEZONE}" ]; then
		# Unix Time
		log "info" "Setting docker timezone to: ${TIMEZONE}"
		runsu "rm /etc/localtime"
		runsu "ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
	else
		log "err" "Invalid timezone for \$TIMEZONE."
		log "err" "\$TIMEZONE: '${TIMEZONE}' does not exist."
		exit 1
	fi
fi
log "info" "Docker date set to: $(date)"



###
### Prepare PHP-FPM
###
if ! set | grep '^PHP_FPM_ENABLE=' >/dev/null 2>&1; then
	log "info" "\$PHP_FPM_ENABLE not set. PHP-FPM support disabled."
else
	if [ "${PHP_FPM_ENABLE}" = "1" ]; then

		# PHP-FPM address
		if ! set | grep '^PHP_FPM_SERVER_ADDR=' >/dev/null 2>&1; then
			log "err" "PHP-FPM enabled, but \$PHP_FPM_SERVER_ADDR not set."
			exit 1
		fi
		if [ "${PHP_FPM_SERVER_ADDR}" = "" ]; then
			log "err" "PHP-FPM enabled, but \$PHP_FPM_SERVER_ADDR is empty."
			exit 1
		fi

		# PHP-FPM port
		if ! set | grep '^PHP_FPM_SERVER_PORT=' >/dev/null 2>&1; then
			log "err" "PHP-FPM enabled, but \$PHP_FPM_SERVER_PORT not set."
			exit 1
		fi
		if [ "${PHP_FPM_SERVER_PORT}" = "" ]; then
			log "err" "PHP-FPM enabled, but \$PHP_FPM_SERVER_PORT is empty."
			exit 1
		fi

		PHP_FPM_CONFIG="/etc/httpd/conf.d/php-fpm.conf"

		# Enable
		log "info" "Enabling PHP-FPM at: ${PHP_FPM_SERVER_ADDR}:${PHP_FPM_SERVER_PORT}"
		runsu "echo '#### PHP-FPM config ####' > ${PHP_FPM_CONFIG}"
		runsu "echo '' >> ${PHP_FPM_CONFIG}"
		runsu "echo '# enablereuse' >> ${PHP_FPM_CONFIG}"
		runsu "echo '# Defining a worker will improve performance' >> ${PHP_FPM_CONFIG}"
		runsu "echo '# And in this case, re-use the worker (dependent on support from the fcgi application)' >> ${PHP_FPM_CONFIG}"
		runsu "echo '# If you have enough idle workers, this would only improve the performance marginally' >> ${PHP_FPM_CONFIG}"
		runsu "echo '#' >> ${PHP_FPM_CONFIG}"
		runsu "echo '# enablereuse requires Apache 2.4.11 or later' >> ${PHP_FPM_CONFIG}"
		runsu "echo '#<Proxy \"fcgi://172.16.238.11:9000/\" enablereuse=on max=10></Proxy>' >> ${PHP_FPM_CONFIG}"
		runsu "echo '<FilesMatch \"\.php\$\">' >> ${PHP_FPM_CONFIG}"
		runsu "echo '    Require all granted' >> ${PHP_FPM_CONFIG}"
		runsu "echo '    # Pick one of the following approaches' >> ${PHP_FPM_CONFIG}"
		runsu "echo '    # Use the standard TCP socket' >> ${PHP_FPM_CONFIG}"
		runsu "echo '    SetHandler \"proxy:fcgi://${PHP_FPM_SERVER_ADDR}:${PHP_FPM_SERVER_PORT}\"' >> ${PHP_FPM_CONFIG}"
		runsu "echo '    # If your version of httpd is 2.4.9 or newer (or has the back-ported feature), you can use the unix domain socket' >> ${PHP_FPM_CONFIG}"
		runsu "echo '    #SetHandler \"proxy:unix:/path/to/app.sock|fcgi://localhost/:9000\"' >> ${PHP_FPM_CONFIG}"
		runsu "echo '</FilesMatch>' >> ${PHP_FPM_CONFIG}"
	fi
fi




###
### Add new Apache configuration dir
###
if ! set | grep '^CUSTOM_HTTPD_CONF_DIR='  >/dev/null 2>&1; then
	log "info" "\$CUSTOM_HTTPD_CONF_DIR not set. No custom include directory added."
else
	# Tell apache to also look into this custom dir for configuratoin
	log "info" "Adding custom include directory: ${CUSTOM_HTTPD_CONF_DIR}"
	runsu "echo 'IncludeOptional ${CUSTOM_HTTPD_CONF_DIR}/*.conf' >> /etc/httpd/conf/httpd.conf"
fi



###
### Start
###
log "info" "Starting $(/usr/sbin/httpd -v 2>&1 | head -1)"
runsu "/usr/sbin/httpd -DFOREGROUND" "1"
