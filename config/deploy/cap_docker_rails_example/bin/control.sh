#!/usr/bin/env bash
CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
. $CONFIG_DIR/CONFIG

if [[ -n "$DOCKER_TAG" ]]
then
  DOCKER_IMAGE=$DOCKER_REPOSITORY:$DOCKER_TAG
else
  DOCKER_IMAGE=$DOCKER_REPOSITORY:current
fi

NGINX_CID_FILE=$CONFIG_DIR/run/nginx.cid
RAILS_CID_FILE=$CONFIG_DIR/run/rails.cid
CURRENT_NGINX_CID=`cat $NGINX_CID_FILE` 
CURRENT_RAILS_CID=`cat $RAILS_CID_FILE`

case "$1" in
  start)
    echo "Starting $DOCKER_IMAGE"
    $DOCKER_BIN start $CURRENT_NGINX_CID $CURRENT_RAILS_CID
    ;;
  stop)
    echo "Stopping $DOCKER_IMAGE"
    $DOCKER_BIN stop $CURRENT_NGINX_CID $CURRENT_RAILS_CID
    ;;
  restart)
    echo "Restarting $DOCKER_IMAGE"
    if [[ -z "$CURRENT_NGINX_CID" || $($DOCKER_BIN port $CURRENT_NGINX_CID 80 2>/dev/null) -eq "$GROUP_B_NGINX_PORT" ]]
    then
      NGINX_CONFIG=$GROUP_A_NGINX_CONFIG
      NGINX_PORT=$GROUP_A_NGINX_PORT
      RAILS_PORT=$GROUP_A_RAILS_PORT
    else
      NGINX_CONFIG=$GROUP_B_NGINX_CONFIG
      NGINX_PORT=$GROUP_B_NGINX_PORT
      RAILS_PORT=$GROUP_B_RAILS_PORT
    fi

    NEW_RAILS_CID=$($DOCKER_BIN run \
                    -e DATABASE_URL=$DATABASE_URL \
                    -p $RAILS_PORT:9292 \
                    -d $DOCKER_IMAGE \
                    /usr/local/rvm/bin/rvm-shell -c \
                    'cd /var/www/rails_app/current && bundle exec puma -e production -p 9292')
    sleep 5 && curl -silent -I http://localhost:$RAILS_PORT > /dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Rails app did not start"
      $DOCKER_BIN logs $NEW_RAILS_CID
      exit 1
    fi

    NEW_NGINX_CID=$($DOCKER_BIN run \
                    -p $NGINX_PORT:80 \
                    -d $DOCKER_IMAGE \
                    /usr/sbin/nginx -c $NGINX_CONFIG)
    curl -silent -I http://localhost:$NGINX_PORT > /dev/null
    if [ "$?" -ne 0 ]
    then
      echo "Nginx did not start"
      $DOCKER_BIN logs $NEW_NGINX_CID
      exit 1
    fi

    echo "Stopping current Rails and Nginx"
    $DOCKER_BIN stop $CURRENT_NGINX_CID $CURRENT_RAILS_CID > /dev/null 2>&1

    echo "Registering new Rails and Nginx"
    echo $NEW_NGINX_CID > $NGINX_CID_FILE
    echo $NEW_RAILS_CID > $RAILS_CID_FILE
    ;;
  *)
    echo "Usage: {start|stop|restart}" >&2
    exit 3
    ;;
esac
