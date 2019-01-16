FROM httpd:2.4
MAINTAINER "cytopia" <cytopia@everythingcli.org>

LABEL \
	name="cytopia's apache 2.4 image" \
	image="devilbox/apache-2.4" \
	vendor="devilbox" \
	license="MIT"

###
### Build arguments
###
ARG VHOST_GEN_GIT_REF=0.15
ARG CERT_GEN_GIT_REF=0.2

ENV BUILD_DEPS \
	git \
	make \
	wget

ENV RUN_DEPS \
	ca-certificates \
	python-yaml \
	supervisor


###
### Runtime arguments
###
ENV MY_USER=daemon
ENV MY_GROUP=daemon
ENV HTTPD_START="httpd-foreground"
ENV HTTPD_RELOAD="/usr/local/apache2/bin/httpd -k stop"


###
### Installation
###

# required packages
RUN set -x \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		${BUILD_DEPS} \
		${RUN_DEPS} \
	\
	# Install vhost-gen
	&& git clone https://github.com/devilbox/vhost-gen \
	&& cd vhost-gen \
	&& git checkout "${VHOST_GEN_GIT_REF}" \
	&& make install \
	&& cd .. \
	&& rm -rf vhost*gen* \
	\
	# Install cert-gen
	&& wget --no-check-certificate -O /usr/bin/ca-gen https://raw.githubusercontent.com/devilbox/cert-gen/${CERT_GEN_GIT_REF}/bin/ca-gen \
	&& wget --no-check-certificate -O /usr/bin/cert-gen https://raw.githubusercontent.com/devilbox/cert-gen/${CERT_GEN_GIT_REF}/bin/cert-gen \
	&& chmod +x /usr/bin/ca-gen \
	&& chmod +x /usr/bin/cert-gen \
	\
	# Install watcherd
	&& wget --no-check-certificate -O /usr/bin/watcherd https://raw.githubusercontent.com/devilbox/watcherd/master/watcherd \
	&& chmod +x /usr/bin/watcherd \
	\
	# Clean-up
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps \
		${BUILD_DEPS} \
	&& rm -rf /var/lib/apt/lists/*

# Add custom config directive to httpd server
RUN set -x \
	&& ( \
		echo "ServerName localhost"; \
		\
		echo "LoadModule http2_module modules/mod_http2.so"; \
		echo "LoadModule proxy_module modules/mod_proxy.so"; \
		echo "LoadModule proxy_http_module modules/mod_proxy_http.so"; \
		echo "LoadModule proxy_http2_module modules/mod_proxy_http2.so"; \
		echo "LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so"; \
		echo "LoadModule rewrite_module modules/mod_rewrite.so"; \
		\
		echo "Include conf/extra/httpd-default.conf"; \
		echo "IncludeOptional /etc/httpd-custom.d/*.conf"; \
		echo "IncludeOptional /etc/httpd/conf.d/*.conf"; \
		echo "IncludeOptional /etc/httpd/vhost.d/*.conf"; \
		\
		echo "LoadModule ssl_module modules/mod_ssl.so"; \
		echo "LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" ;\
		echo "Listen 443"; \
		echo "SSLCipherSuite HIGH:MEDIUM:!MD5:!RC4:!3DES"; \
		echo "SSLProxyCipherSuite HIGH:MEDIUM:!MD5:!RC4:!3DES"; \
		echo "SSLHonorCipherOrder on"; \
		echo "SSLProtocol all -SSLv3"; \
		echo "SSLProxyProtocol all -SSLv3"; \
		echo "SSLPassPhraseDialog  builtin"; \
		echo "SSLSessionCache        \"shmcb:/usr/local/apache2/logs/ssl_scache(512000)\""; \
		echo "SSLSessionCacheTimeout  300"; \
		\
		echo "HTTPProtocolOptions unsafe"; \
	) >> /usr/local/apache2/conf/httpd.conf

# create directories
RUN set -x \
	&& mkdir -p /etc/httpd-custom.d \
	&& mkdir -p /etc/httpd/conf.d \
	&& mkdir -p /etc/httpd/vhost.d \
	&& mkdir -p /var/www/default/htdocs \
	&& mkdir -p /shared/httpd \
	&& chmod 0775 /shared/httpd \
	&& chown ${MY_USER}:${MY_GROUP} /shared/httpd


###
### Copy files
###
COPY ./data/vhost-gen/main.yml /etc/vhost-gen/main.yml
COPY ./data/vhost-gen/mass.yml /etc/vhost-gen/mass.yml
COPY ./data/create-vhost.sh /usr/local/bin/create-vhost.sh
COPY ./data/docker-entrypoint.d /docker-entrypoint.d
COPY ./data/docker-entrypoint.sh /docker-entrypoint.sh


###
### Ports
###
EXPOSE 80
EXPOSE 443


###
### Volumes
###
VOLUME /shared/httpd
VOLUME /ca


###
### Signals
###
STOPSIGNAL SIGTERM


###
### Entrypoint
###
ENTRYPOINT ["/docker-entrypoint.sh"]
