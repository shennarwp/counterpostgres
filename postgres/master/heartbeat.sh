#!/bin/bash

# WILL BE RUN IN BACKGROUND
while true
do
	# CHECK AND PING IF ANOTHER DATABASE INSTANCE RUNNING
	nslookup ${PG_SLAVE_HOST} > /dev/null
	rc=$?
	ping -c 1 -W 10 ${PG_SLAVE_HOST} > /dev/null
	rd=$?

	# IF NOT, THEN CREATE TRIGGER FILE TO PROMOTE ITSELF AS MASTER
	# WAIT 10 SECONDS AND REMOVE THIS TRIGGER FILE AGAIN
	# SO THAT LATER IF THIS INSTANCE IS RESTARTED,
	# IT WILL NOT AUTOMATICALLY FIND TRIGGER FILE AND AUTOMATICALLY
	# START AS MASTER
	if ! [[ $rc -eq 0 && $rd -eq 0 ]]; then
		touch /tmp/touch_me_to_promote_to_me_master
		sleep 10
		rm /tmp/touch_me_to_promote_to_me_master
	fi
	sleep 10
done
