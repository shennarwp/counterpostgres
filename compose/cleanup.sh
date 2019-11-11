#!/bin/bash

docker container rm db_counter_master && docker image rm db_counter_master && docker volume rm master_home
docker container rm db_counter_slave && docker image rm db_counter_slave && docker volume rm slave_home