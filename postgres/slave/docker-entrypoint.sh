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
		#sed -i "s/^archive_command =.*/archive_command = 'rsync -a %p \${POSTGRES_USER}@\${PG_SLAVE_HOST}:\${ARCHIVE_DIR}\/%f'/g" ${PGDATA}/postgresql.conf
		sed -i "s/^archive_command =.*/archive_command = 'cd .'/g" ${PGDATA}/postgresql.conf
	fi

# Mark this instance as SLAVE, create recovery.conf file
set -e

cat > ${PGDATA}/recovery.conf <<EOF
standby_mode = on
primary_conninfo = 'host=${PG_MASTER_HOST} port=${PG_MASTER_PORT:-5432} user=${PG_REP_USER} password=${PG_REP_PASSWORD}'
restore_command = 'cp ${ARCHIVE_DIR}/%f %p'
trigger_file = '${TRIGGER_FILE}'
recovery_target_timeline='latest'
EOF
chown ${POSTGRES_USER} ${PGDATA} -R
chmod 700 ${PGDATA} -R

echo "STARTED INSTANCE AS SLAVE"

# MASTER does not exist, remove any existing recovery.conf file
else
	echo "STARTED INSTANCE AS MASTER"
	if [ -f ${PGDATA}/recovery.conf ]; then
		rm ${PGDATA}/recovery.conf
	fi
fi

# Create directory for archiving if it does not yet exist
if [ ! -d ${ARCHIVE_DIR} ]; then
	mkdir -p ${ARCHIVE_DIR}
	chmod 700 ${ARCHIVE_DIR}
	chown -R ${POSTGRES_USER}:${POSTGRES_USER} ${ARCHIVE_DIR}
fi

# Initialize heartbeat script
nohup /heartbeat.sh > /dev/null 2>&1 &

# Start the instance as user postgres
gosu ${POSTGRES_USER} ${POSTGRES_USER}
