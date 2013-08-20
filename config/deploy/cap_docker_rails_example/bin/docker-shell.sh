#!/usr/bin/env bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $SCRIPT_DIR/../CONFIG

echo "Running against $DOCKER_REPOSITORY:$DOCKER_TAG ..."
$DOCKER_BIN history $DOCKER_REPOSITORY:$DOCKER_TAG > /dev/null || exit $?

CID=$($DOCKER_BIN run \
      -e DATABASE_URL=$DATABASE_URL \
      -d $DOCKER_REPOSITORY:$DOCKER_TAG /usr/local/rvm/bin/rvm-shell "$@")

if [ `docker wait $CID` -ne 0 ]
then 
     docker logs $CID
     exit 1
else
     echo "Committing $DOCKER_REPOSITORY:$DOCKER_TAG"
     docker commit $CID $DOCKER_REPOSITORY $DOCKER_TAG > /dev/null
     docker logs $CID
fi
