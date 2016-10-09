#!/bin/sh -eu


##
## VARIABLES
##
VERSION_GOSU="1.2"
HTTPD_CONF="/etc/httpd/conf/httpd.conf"




MY_USER="apache"
MY_GROUP="apache"
MY_UID="48"
MY_GID="48"


##
## FUNCTIONS
##
print_headline() {
	_txt="${1}"
	_blue="\033[0;34m"
	_reset="\033[0m"

	printf "${_blue}\n%s\n${_reset}" "--------------------------------------------------------------------------------"
	printf "${_blue}- %s\n${_reset}" "${_txt}"
	printf "${_blue}%s\n\n${_reset}" "--------------------------------------------------------------------------------"
}

run() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}


################################################################################
# MAIN ENTRY POINT
################################################################################

##
## Adding Users
##
print_headline "1. Adding Users"
run "groupadd -g ${MY_GID} -r ${MY_GROUP}"
run "adduser ${MY_USER} -u ${MY_UID} -M -s /sbin/nologin -g ${MY_GROUP}"



###
### Adding Repositories
###
### (required for mod_xsendfile)
print_headline "2. Adding Repository"
run "yum -y install epel-release"



###
### Updating Packages
###
print_headline "3. Updating Packages Manager"
run "yum clean all"
run "yum -y check"
run "yum -y update"



###
### Installing Packages
###
print_headline "4. Installing Packages"
run "yum -y install \
	httpd \
	mod_xsendfile \
	php \
	"
# PHP is required (pulls mod_php) so that `php_admin_value`
# is allowed inside apache directives




###
### Configure Apache
###
### (Remove all custom config)
###
print_headline "5. Configure Apache"

# Clean all configs
if [ ! -d "/etc/httpd/conf.d/" ]; then
	run "mkdir -p /etc/httpd/conf.d/"
else
	run "rm -rf /etc/httpd/conf.d/*"
fi

# User and Group
run "sed -i'' 's/^User[[:space:]]*=.*$/User = ${MY_USER}/g' ${HTTPD_CONF}"
run "sed -i'' 's/^Group[[:space:]]*=.*$/Group = ${MY_GROUP}/g' ${HTTPD_CONF}"

# Listen and ServerName
run "sed -i'' 's/^Listen[[:space:]].*$/Listen 0.0.0.0:80/g' ${HTTPD_CONF}"
run "sed -i'' 's/^#ServerName[[:space:]].*$/ServerName localhost:80/g' ${HTTPD_CONF}"



###
### Installing Gosu
###
print_headline "6. Installing Gosu"
run "gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4"
run "curl -SL -o /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/${VERSION_GOSU}/gosu-amd64 --retry 999 --retry-max-time 0 -C -"
run "curl -SL -o /usr/local/bin/gosu.asc https://github.com/tianon/gosu/releases/download/${VERSION_GOSU}/gosu-amd64.asc --retry 999 --retry-max-time 0 -C -"
run "gpg --verify /usr/local/bin/gosu.asc"
run "rm /usr/local/bin/gosu.asc"
run "rm -rf /root/.gnupg/"
run "chown root /usr/local/bin/gosu"
run "chmod +x /usr/local/bin/gosu"
run "chmod +s /usr/local/bin/gosu"



###
### Creating Mass VirtualHost dirs
###
print_headline "7. Creating Mass VirtualHost dirs"
run "mkdir -p /shared/httpd"
run "chmod 775 /shared/httpd"
run "chown ${MY_USER}:${MY_GROUP} /shared/httpd"



###
### Cleanup unecessary packages
###
print_headline "8. Cleanup unecessary packages"
run "yum -y autoremove"