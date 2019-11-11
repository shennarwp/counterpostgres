#!/bin/bash

# This is heartbeat-script,
# the host will try to ping and reach another host,
# determine if another whether another host is reachable.
# This script is supposed to be run in background.
while true
do
	# Check and ping if another database instance is already up and running
	nslookup ${PG_SLAVE_HOST} > /dev/null
	reachable=$?
	ping -c 1 -W 10 ${PG_SLAVE_HOST} > /dev/null
	pingable=$?

	# Another host is down
	# check if it is currently running as standby / slave
	# if it is now the master, then skip
	# if it is now the slave, then promote itself as master
	if ! [[ $reachable -eq 0 && $pingable -eq 0 ]]; then
		recoverystatus=$(psql --username "${POSTGRES_USER}" -tA -c "SELECT pg_is_in_recovery();")
		if [ $recoverystatus == "t" ]; then
			psql --username "${POSTGRES_USER}" -c "SELECT pg_promote();"
		fi
	fi
	sleep 10
done
