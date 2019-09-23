FROM postgres:alpine

ENV GOSU_VERSION 1.11

ADD ./gosu /usr/bin/
RUN chmod +x /usr/bin/gosu

# ENV GOSU_VERSION 1.10

# ADD ./gosu /usr/bin/
# RUN chmod +x /usr/bin/gosu

RUN apk add --update iputils
RUN apk add --update htop

# COPY ./setup-slave.sh /docker-entrypoint-initdb.d
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD gosu ${POSTGRES_USER} ${POSTGRES_USER}
#CMD ["gosu", ${POSTGRES_USER}, ${POSTGRES_USER}]