#!/bin/bash

# TODO: make compatitable w zsh, etc.
script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

postgres_image="postgres:14"
container_name="sde_test_db"

postgres_env_path="$script_path/../postgres.env"
sql_include_path="$script_path/../sql"

# include postgres .env variables
# $POSTGRES_USER, $POSTGRES_DB, $POSTGRES_PASSWORD
source $postgres_env_path

docker pull $postgres_image

docker stop $container_name && docker rm $container_name

docker run \
    --name $container_name \
    --env-file $postgres_env_path \
    --mount type=bind,source=$sql_include_path,target=/sql_include \
    -p 5432:5432 \
    -d \
    $postgres_image


# TODO: use timeouts to force fail after n secs

# wait for pg
# https://postgrespro.ru/docs/postgresql/9.6/app-pg-isready
until [[ "$(docker exec $container_name pg_isready)" == *"accepting"* ]]; do
    echo "waiting for postgres to be available..."
    sleep 1;
done;

# wait for $POSTGRES_DB to be available
# https://stackoverflow.com/questions/14549270/check-if-database-exists-in-postgresql-using-shell
until [[ "$(docker exec $container_name psql -U $POSTGRES_USER -lqt | cut -d \| -f 1 | grep -w $POSTGRES_DB)" ]]; do
    echo "waiting for postgres $POSTGRES_DB database to be available..."
    sleep 1;
done;

# fill data
docker exec $container_name psql -U $POSTGRES_USER -d $POSTGRES_DB -a -f /sql_include/init_db/demo.sql

# fill practice result
docker exec $container_name psql -U $POSTGRES_USER -d $POSTGRES_DB -a -f /sql_include/main/calc.sql


