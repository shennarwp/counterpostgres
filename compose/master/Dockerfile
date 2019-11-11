# Dockerfile to build this postgres instance image for consecutive / later time
# will be used ONLY by docker-compose.yml

FROM postgres:12.0


COPY ./init.sh /docker-entrypoint-initdb.d/init.sh

COPY ./docker-entrypoint.sh ./heartbeat.sh /

RUN set -eux \
	&& apt-get update \
	&& apt-get install -y \
		gosu \
		iputils-ping \
		dnsutils \
	&& rm -rf /var/lib/apt/lists/* \
	&& chmod +x /docker-entrypoint-initdb.d/init.sh \
	&& chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]