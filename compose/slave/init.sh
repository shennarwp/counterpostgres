#!/bin/bash

# Initialization script for this postgres instance image:
# * set default user password
# * create the role for replication from another instance
# * create the database and table for the program torpedoanmeldung
# * create the configuration for replication and archiving

echo "Configuring the Database for the first time..."

# Set password for the user, create user for replication and then
# Create the database
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
	ALTER ROLE "$POSTGRES_USER" WITH ENCRYPTED PASSWORD "$POSTGRES_PASSWORD";
	CREATE USER ${PG_REP_USER} REPLICATION LOGIN CONNECTION LIMIT 100 ENCRYPTED PASSWORD '${PG_REP_PASSWORD}';
	CREATE DATABASE counter;
EOSQL

# Create tables for the database
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    CREATE TABLE IF NOT EXISTS count(count int);
EOSQL

# Configuration file
cat >> ${PGDATA}/postgresql.conf <<EOF

# configuration for primary / master
wal_level = replica
archive_mode = on
archive_command = 'cp %p ${PGDATA}/archive/%f'
max_wal_senders = 2
wal_keep_segments = 8

# configuration for standby / slave server
hot_standby = on
restore_command = 'cp ${PGDATA}/archive/%f %p'
recovery_target_timeline ='latest'
EOF

# Listen to all interfaces
# TODO: restrict listening
echo "host replication all 0.0.0.0/0 md5" >> "${PGDATA}/pg_hba.conf"
echo "host all all 0.0.0.0/0 md5" >> "${PGDATA}/pg_hba.conf"
