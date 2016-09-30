##
## Apache 2.4
##

FROM centos:7
MAINTAINER "cytopia" <cytopia@everythingcli.org>

# PHP Config
COPY ./config/php.ini /etc/php.ini

# MySQL Config
COPY ./config/my.cnf /etc/my.cnf

# Apache Config
COPY ./config/httpd.conf /etc/httpd/conf/httpd.conf
COPY ./config/httpd-defaults.conf /etc/httpd/conf.d/

# Apache vHosts
COPY ./config/vhost_default.conf /etc/httpd/conf/vserver/00-vhost_default.conf
COPY ./config/vhost_mass.conf /etc/httpd/conf/vserver/01-vhost_mass.conf

# Mass virtualhost fixes
COPY ./bin/fix-virtual-docroot.php /etc/httpd/bin/
COPY ./bin/splitlogs.php /etc/httpd/bin/


# Copy scripts
COPY ./scripts/docker-install.sh /
COPY ./scripts/docker-entrypoint.sh /


# Install
RUN /docker-install.sh


##
## Become apache in order to have mounted files
## with apache user rights
##
User apache

# Autostart
ENTRYPOINT ["/docker-entrypoint.sh"]
