#!/bin/bash

set -eu -o pipefail

echo "Customizing environment for ArkCase"

[ -v JAVA_OPTS ] || JAVA_OPTS=

# Fetch the DB credentials and stuck them in JAVA_OPTS
if [ -v ARK_DB_SECRET_ARN ]; then
    response=$(aws secretsmanager get-secret-value --secret-id "$ARK_DB_SECRET_ARN")
    secret=$(echo "$response" | jq -r .SecretString)
    host=$(echo "$secret" | jq -r .host)
    port=$(echo "$secret" | jq -r .port)
    dbname=$(echo "$secret" | jq -r .dbname)
    username=$(echo "$secret" | jq -r .username)
    password=$(echo "$secret" | jq -r .password)
    JAVA_OPTS="$JAVA_OPTS -Ddb.url=\"jdbc:mariadb://$host:$port/$dbname?autoReconnect=true&useUnicode=true&characterEncoding=UTF-8\""
    JAVA_OPTS="$JAVA_OPTS -Ddb.username=$username -Ddb.password=$password"
    echo "MariaDB host: $host"
    echo "MariaDB port: $port"
    echo "MariaDB dbname: $dbname"
    echo "MariaDB username: $username"
    echo "XXX mariadb password: $password"
    echo 'Added `-Ddb.url`, `-Ddb.username` and `-Ddb.password` to `JAVA_OPTS`' > /dev/stdout
    echo 'show databases;' | mysql -h $host -u $username -p$password  # XXX
fi

# Fetch the ActiveMQ credentials and stuck them in JAVA_OPTS
if [ -v ARK_ACTIVEMQ_SECRET_ARN ]; then
    response=$(aws secretsmanager get-secret-value --secret-id "$ARK_ACTIVEMQ_SECRET_ARN")
    secret=$(echo "$response" | jq -r .SecretString)
    username=$(echo "$secret" | jq -r .username)
    password=$(echo "$secret" | jq -r .password)
    JAVA_OPTS="$JAVA_OPTS -Dmessaging.broker.username=$username -Dmessaging.broker.password=$password"
    echo "ActiveMQ username: $username"
    echo 'Added `-Dmessaging.broker.username` and `-Dmessaging.broker.password` to `JAVA_OPTS`'
fi

export JAVA_OPTS
exec /usr/local/tomcat/bin/catalina.sh run -security
