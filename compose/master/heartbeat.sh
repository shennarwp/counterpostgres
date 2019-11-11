#!/bin/bash

# This is heartbeat-script,
# the host will try to ping and reach another host,
# determine if another whether another host is reachable.
# This script is supposed to be run in background.
while true
do
	# Check and ping if another database instance is already up and running
	nslookup ${PG_SLAVE_HOST} > /dev/null
	rc=$?
	ping -c 1 -W 10 ${PG_SLAVE_HOST} > /dev/null
	rd=$?

	# If not, then create trigger file, which will be
	# automatically detected by PostgreSQL service
	# which then promote itself as master.
	# Wait 10 seconds until the failover process is finished
	# and then remove the trigger file again so that later
	# if this instance is restarted as slave
	# it will not automatically detect the trigger file and
	# start as master
	if ! [[ $rc -eq 0 && $rd -eq 0 ]]; then
		touch ${TRIGGER_FILE}
		sleep 10
		rm ${TRIGGER_FILE}
	fi
	sleep 10
done
