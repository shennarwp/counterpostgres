#!/bin/bash

# PING MASTER, IF EXIST START AS SLAVE
if ping -c 1 -W 1 ${PG_MASTER_HOST:?missing environment variable. PG_MASTER_HOST must be set}; then

	# IF NEVER INITIALIZED BEFORE
	if [ ! -s "${PGDATA}/PG_VERSION" ]; then
		echo "*:*:*:${PG_REP_USER}:${PG_REP_PASSWORD}" > ~/.pgpass
		chmod 0600 ~/.pgpass

		# RESTORE FROM MASTER BACKUP
		until pg_basebackup -h ${PG_MASTER_HOST} -D ${PGDATA} -U ${PG_REP_USER} -vP -W
	    do
	        echo "Waiting for master to connect..."
	        sleep 1s
		done
		echo "host replication all 0.0.0.0/0 md5" >> "${PGDATA}/pg_hba.conf"

# RECOVERY CONFIGURATION FILE
set -e

cat > ${PGDATA}/recovery.conf <<EOF
standby_mode = on
primary_conninfo = 'host=${PG_MASTER_HOST} port=${PG_MASTER_PORT:-5432} user=${PG_REP_USER} password=${PG_REP_PASSWORD}'
restore_command = 'cp ${PGDATA}/archive/%f %p'
trigger_file = '/tmp/touch_me_to_promote_to_me_master'
EOF
chown ${POSTGRES_USER} ${PGDATA} -R
chmod 700 ${PGDATA} -R

	fi

fi

# REPLICATION LEVEL
sed -i 's/wal_level = hot_standby/wal_level = replica/g' ${PGDATA}/postgresql.conf

# DIRECTORY FOR ARCHIVE
mkdir -p ${PGDATA}/archive
chmod 700 ${PGDATA}/archive
chown -R ${POSTGRES_USER}:${POSTGRES_USER} ${PGDATA}/archive

exec "$@"
