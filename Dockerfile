FROM httpd:2.4
MAINTAINER "cytopia" <cytopia@everythingcli.org>


###
### Labels
###
LABEL \
	name="cytopia's Apache 2.4 Image" \
	image="apache-2.4" \
	vendor="cytopia" \
	license="MIT" \
	build-date="2017-09-28"


###
### Installation
###

# required packages
RUN set -x \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		make \
		python-yaml \
		supervisor \
		wget \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove

# vhost-gen
RUN set -x \
	&& wget --no-check-certificate -O vhost_gen.tar.gz https://github.com/devilbox/vhost-gen/archive/master.tar.gz \
	&& tar xfvz vhost_gen.tar.gz \
	&& cd vhost-gen-master \
	&& make install \
	&& cd .. \
	&& rm -rf vhost*gen*

# watcherd
RUN set -x \
	&& wget --no-check-certificate -O /usr/bin/watcherd https://raw.githubusercontent.com/devilbox/watcherd/master/watcherd \
	&& chmod +x /usr/bin/watcherd

# cleanup
RUN set -x \
	&& apt-get update \
	&& apt-get remove -y \
		make \
		wget \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove

# Add custom config directive to httpd server
RUN set -x \
	&& ( \
		echo "ServerName localhost"; \
		echo "LoadModule proxy_module modules/mod_proxy.so"; \
		echo "LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so"; \
		echo "LoadModule rewrite_module modules/mod_rewrite.so"; \
		echo "Include conf/extra/httpd-default.conf"; \
		echo "IncludeOptional /etc/httpd-custom.d/*.conf"; \
		echo "IncludeOptional /etc/httpd/conf.d/*.conf"; \
		echo "IncludeOptional /etc/httpd/vhost.d/*.conf"; \
	) >> /usr/local/apache2/conf/httpd.conf

# create directories
RUN set -x \
	&& mkdir -p /etc/httpd-custom.d \
	&& mkdir -p /etc/httpd/conf.d \
	&& mkdir -p /etc/httpd/vhost.d \
	&& mkdir -p /var/www/default/htdocs \
	&& mkdir -p /shared/httpd \
	&& chmod 0775 /shared/httpd \
	&& chown daemon:daemon /shared/httpd


###
### Copy files
###
COPY ./data/vhost-gen/conf.yml /etc/vhost-gen/conf.yml
COPY ./data/vhost-gen/main.yml /etc/vhost-gen/main.yml
COPY ./data/supervisord.conf /etc/supervisord.conf
COPY ./data/docker-entrypoint.sh /docker-entrypoint.sh


###
### Ports
###
EXPOSE 80


###
### Volumes
###
VOLUME /shared/httpd


###
### Signals
###
STOPSIGNAL SIGTERM


###
### Entrypoint
###
ENTRYPOINT ["/docker-entrypoint.sh"]
