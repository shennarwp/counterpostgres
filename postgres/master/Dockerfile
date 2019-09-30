# Dockerfile to build this postgres instance image for consecutive / later time
# will be used ONLY by docker-compose.yml

FROM postgres:alpine

ENV GOSU_VERSION 1.11

ADD ./gosu /usr/bin/

COPY ./docker-entrypoint.sh ./heartbeat.sh /

RUN chmod +x /usr/bin/gosu \
	\
	&& chmod +x /docker-entrypoint.sh \
	\
	&& apk add --update iputils \
	\
	&& apk add --update htop \
	\
	&& apk add rsync openssh


ENTRYPOINT ["/docker-entrypoint.sh"]
