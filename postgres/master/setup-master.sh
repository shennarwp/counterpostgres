#!/bin/bash

echo "host replication all 0.0.0.0/0 md5" >> "${PGDATA}/pg_hba.conf"

set -e
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    CREATE USER ${PG_REP_USER} REPLICATION LOGIN CONNECTION LIMIT 100 ENCRYPTED PASSWORD '${PG_REP_PASSWORD}';
EOSQL

cat >> ${PGDATA}/postgresql.conf <<EOF

wal_level = replica
archive_mode = on
archive_command = 'cp %p ${PGDATA}/archive/%f'
max_wal_senders = 2
wal_keep_segments = 8
hot_standby = on
EOF

mkdir -p ${PGDATA}/archive
chmod 700 ${PGDATA}/archive
chown -R ${POSTGRES_USER}:${POSTGRES_USER} ${PGDATA}/archive
