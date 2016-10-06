##
## Apache 2.4
##

FROM centos:7
MAINTAINER "cytopia" <cytopia@everythingcli.org>

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
