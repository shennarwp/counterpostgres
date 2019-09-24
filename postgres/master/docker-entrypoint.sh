#!/bin/bash

# The docker entrypoint script for this postgres database instance

# PING SLAVE, IF EXIST START AS SLAVE
nslookup ${PG_SLAVE_HOST}
rc=$?
if [[ $rc -eq 0 ]]; then

	# IF NEVER INITIALIZED BEFORE
	if [ ! -s "${PGDATA}/PG_VERSION" ]; then
		echo "*:*:*:${PG_REP_USER}:${PG_REP_PASSWORD}" > ~/.pgpass
		chmod 0600 ~/.pgpass

		# RESTORE FROM SLAVE BACKUP (FROM 0)
		until pg_basebackup -h ${PG_SLAVE_HOST} -D ${PGDATA} -U ${PG_REP_USER} -vP -W
    	do
        	echo "Waiting for master to connect..."
        	sleep 1s
		done
	fi

# MARK THIS INSTANCE AS SLAVE, CREATE RECOVERY.CONF FILE
set -e

cat > ${PGDATA}/recovery.conf <<EOF
standby_mode = on
primary_conninfo = 'host=${PG_SLAVE_HOST} port=${PG_SLAVE_PORT:-5432} user=${PG_REP_USER} password=${PG_REP_PASSWORD}'
restore_command = 'cp ${PGDATA}/archive/%f %p'
trigger_file = '/tmp/touch_me_to_promote_to_me_master'
recovery_target_timeline='latest'
EOF
chown ${POSTGRES_USER} ${PGDATA} -R
chmod 700 ${PGDATA} -R

echo "STARTED INSTANCE AS SLAVE"

# SLAVE DOES NOT EXIST, INITIALIZE AS MASTER
else
	echo "STARTED INSTANCE AS MASTER"
	rm ${PGDATA}/recovery.conf
fi

# LISTEN TO ALL
echo "host replication all 0.0.0.0/0 md5" >> "${PGDATA}/pg_hba.conf"

# REPLICATION LEVEL
sed -i 's/wal_level = hot_standby/wal_level = replica/g' ${PGDATA}/postgresql.conf

# DIRECTORY FOR ARCHIVE
mkdir -p ${PGDATA}/archive
chmod 700 ${PGDATA}/archive
chown -R ${POSTGRES_USER}:${POSTGRES_USER} ${PGDATA}/archive

# INITIALIZE HEARTBEAT SCRIPT
nohup /heartbeat.sh > /dev/null 2>&1 &
gosu ${POSTGRES_USER} ${POSTGRES_USER}
