#!/bin/bash

# The docker entrypoint script for this postgres database instance

# Ping MASTER
nslookup ${PG_MASTER_HOST}
rc=$?

# If MASTER exist
if [[ $rc -eq 0 ]]; then

	# Remove any trigger file if exist, so it does not start automatically as master
	if [[ -f ${TRIGGER_FILE} ]]; then
    	rm ${TRIGGER_FILE}
	fi

	# If this instance has never been initialized before
	if [ ! -s "${PGDATA}/PG_VERSION" ]; then
		echo "*:*:*:${PG_REP_USER}:${PG_REP_PASSWORD}" > ~/.pgpass
		chmod 0600 ~/.pgpass

		# Restore / rebuild database from MASTER backup, from 0
		until pg_basebackup -h ${PG_MASTER_HOST} -D ${PGDATA} -U ${PG_REP_USER} -vP -W
	    do
	        echo "Waiting for master to connect..."
	        sleep 1s
		done
	fi

# Mark this instance as SLAVE, create recovery.conf file
set -e

cat > ${PGDATA}/recovery.conf <<EOF
standby_mode = on
primary_conninfo = 'host=${PG_MASTER_HOST} port=${PG_MASTER_PORT:-5432} user=${PG_REP_USER} password=${PG_REP_PASSWORD}'
restore_command = 'cp ${PGDATA}/archive/%f %p'
trigger_file = '${TRIGGER_FILE}'
recovery_target_timeline='latest'
EOF
chown ${POSTGRES_USER} ${PGDATA} -R
chmod 700 ${PGDATA} -R

echo "STARTED INSTANCE AS SLAVE"

# MASTER does not exist, remove any existing recovery.conf file
else
	echo "STARTED INSTANCE AS MASTER"
	rm ${PGDATA}/recovery.conf
fi

# Listen to all interface
echo "host replication all 0.0.0.0/0 md5" >> "${PGDATA}/pg_hba.conf"

# Replication level
sed -i 's/wal_level = hot_standby/wal_level = replica/g' ${PGDATA}/postgresql.conf

# Create directory for archiving
mkdir -p ${PGDATA}/archive
chmod 700 ${PGDATA}/archive
chown -R ${POSTGRES_USER}:${POSTGRES_USER} ${PGDATA}/archive

# Initialize heartbeat script
nohup /heartbeat.sh > /dev/null 2>&1 &

# Start the instance as user postgres
gosu ${POSTGRES_USER} ${POSTGRES_USER}
