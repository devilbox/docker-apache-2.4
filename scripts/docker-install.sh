#!/bin/sh -eu


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
print_headline "0. Adding Users"

# Apache User
run "echo 'apache:x:48:' >> /etc/group"
run "adduser apache -u 48 -s /bin/bash -d /home/apache -g apache"

# Deploy User
run "echo 'metopia:x:510:' >> /etc/group"
run "adduser cytopia -u 1000 -s /bin/bash -d /home/cytopia -g metopia"

# Link group of both
run "usermod -a -G apache cytopia"
run "usermod -a -G metopia apache"




###
### Adding Repositories
###
print_headline "1. Adding Repository"
run "yum -y install epel-release"
run "rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm"
run "yum-config-manager --enable remi"
run "yum-config-manager --enable remi-php56"
run "yum-config-manager --disable remi-php70"
run "yum-config-manager --disable remi-php71"



###
### Updating Packages
###
print_headline "2. Updating Packages Manager"
run "yum clean all"
run "yum -y check"
run "yum -y update"



###
### Installing Packages
###
print_headline "3. Installing Packages"
run "yum -y install \
	httpd \
	php \
	php-bcmath \
	php-cli \
	php-common \
	php-gd \
	php-imap \
	php-intl \
	php-ldap \
	php-magickwand \
	php-mbstring \
	php-mcrypt \
	php-mysql \
	php-mysqlnd \
	php-opcache \
	php-pdo \
	php-pspell \
	php-recode \
	php-soap \
	php-tidy \
	php-xml \
	php-xmlrpc \
	php-pecl-uploadprogress
	"



###
### Installing additional HTTP Modules
###
print_headline "4. Installing additional HTTP Modules"
run "yum -y groupinstall 'Development Tools'"
run "yum -y install httpd-devel"

run "cd /tmp && curl -O  https://tn123.org/mod_xsendfile/mod_xsendfile-0.12.tar.gz"
run "cd /tmp && tar xfvz mod_xsendfile-0.12.tar.gz"
run "cd /tmp/mod_xsendfile-0.12 && apxs -cia mod_xsendfile.c"
run "rm -rf /tmp/mod_xsendfile*"

run "yum -y remove httpd-devel"
run "yum -y groupremove 'Development Tools'"



###
### Configure Apache
###
print_headline "5. Configure Apache"
if [ -f "/etc/httpd/conf.d/welcome.conf" ]; then
	run "mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.off"
fi
if [ -f "/etc/httpd/conf.d/userdir.conf" ]; then
	run "mv /etc/httpd/conf.d/userdir.conf /etc/httpd/conf.d/userdir.conf.off"
fi



###
### Installing Socat (for tunneling remote mysql to localhost)
###
print_headline "6. Installing Socat"
run "yum -y install socat"



###
### Installing Gosu
###
print_headline "7. Installing Gosu"
run "gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4"
run "curl -o /usr/local/bin/gosu -SL https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64"
run "curl -o /usr/local/bin/gosu.asc -SL https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64.asc"
run "gpg --verify /usr/local/bin/gosu.asc"
run "rm /usr/local/bin/gosu.asc"
run "rm -rf /root/.gnupg/"
run "chown root /usr/local/bin/gosu"
run "chmod +x /usr/local/bin/gosu"
run "chmod +s /usr/local/bin/gosu"



###
### Creating Paths
###
print_headline "8. Creating Paths"
run "mkdir -p /shared/httpd"
run "chmod 775 /shared/httpd"
run "chown apache:apache /shared/httpd"