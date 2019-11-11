#!/bin/bash

# The docker entrypoint script for this postgres database instance

# Ping MASTER
nslookup ${PG_MASTER_HOST}
reachable=$?
ping -c 1 -W 10 ${PG_MASTER_HOST}
pingable=$?

# If MASTER exist
if [[ $reachable -eq 0 && $pingable -eq 0 ]]; then
	echo "STARTED INSTANCE AS SLAVE"

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

		echo "primary_conninfo = 'host=${PG_MASTER_HOST} port=5432 user=${PG_REP_USER} password=${PG_REP_PASSWORD}'" >> ${PGDATA}/postgresql.conf

		# Archive folder
		mkdir -p ${PGDATA}/archive
		chown ${POSTGRES_USER} ${PGDATA} -R
		chmod 700 ${PGDATA} -R
	fi

	# mark / signal this instance as standby / slave server
	touch "${PGDATA}/standby.signal"

# SLAVE does not exist
else
	echo "STARTED INSTANCE AS MASTER"

	# If this instance has never been initialized before
	if [ ! -s "$PGDATA/PG_VERSION" ]; then

		# Initialize the database for the first time, start
		gosu "${POSTGRES_USER}" initdb
		gosu "${POSTGRES_USER}" pg_ctl -D "$PGDATA" -w start

		# Run all .sql and .sh scripts in this folder /docker-entrypoint-initdb.d/
		for f in /docker-entrypoint-initdb.d/*; do
			case "$f" in
				*.sh)
					if [ -x "$f" ]; then
						echo "$0: running $f"
						"$f"
					else
						echo "$0: sourcing $f"
						. "$f"
					fi
					;;
				*.sql)    echo "$0: running $f"; "${psql[@]}" -f "$f"; echo ;;
				#*.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${psql[@]}"; echo ;;
				*)        echo "$0: ignoring $f" ;;
			esac
			echo
		done

		echo "primary_conninfo = 'host=${PG_MASTER_HOST} port=5432 user=${PG_REP_USER} password=${PG_REP_PASSWORD}'" >> ${PGDATA}/postgresql.conf

		# Archive folder
		mkdir -p ${PGDATA}/archive
		chown ${POSTGRES_USER} ${PGDATA} -R
		chmod 700 ${PGDATA} -R

		gosu "${POSTGRES_USER}" pg_ctl -D "$PGDATA" -m fast -w stop

	fi
fi

# Initialize heartbeat script
nohup /heartbeat.sh > /dev/null 2>&1 &

# start the postgres service
gosu "${POSTGRES_USER}" postgres
