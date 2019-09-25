#!/bin/bash

# Initialization script for this postgres instance image:
# * create the role for replication from another instance
# * create the table for the program counter
# * create the configuration for replication and archiving

echo "Configuring the Database for the first time..."

# Listen to all interfaces
# TODO: only listen to another postgres instance IP
echo "host replication all 0.0.0.0/0 md5" >> "${PGDATA}/pg_hba.conf"

# Create role for replication from another instance
# Create table for the program counter
set -e
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    CREATE USER ${PG_REP_USER} REPLICATION LOGIN CONNECTION LIMIT 100 ENCRYPTED PASSWORD '${PG_REP_PASSWORD}';
    CREATE TABLE IF NOT EXISTS count(count int);
EOSQL

# Configuration file for standby / replication
cat >> ${PGDATA}/postgresql.conf <<EOF

wal_level = replica
archive_mode = on
archive_command = 'cp %p ${PGDATA}/archive/%f'
max_wal_senders = 2
wal_keep_segments = 8
hot_standby = on
EOF

# Archive folder
mkdir -p ${PGDATA}/archive
chmod 700 ${PGDATA}/archive
chown -R ${POSTGRES_USER}:${POSTGRES_USER} ${PGDATA}/archive

# Remove this initialization script, so that later if this database restarted,
# it will not be initialized again, but instead directly follow and catch up with another
# postgres instance
echo "Removing initialization scripts..."

# Wait 10 seconds until the postgres service is started, then remove
sleep 10
rm /docker-entrypoint-initdb.d/setup-master.sh
