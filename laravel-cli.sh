#!/bin/bash
set -e

if [ "$(id -u)" -eq 0 ]; then
  echo 'This script can only run by user (non-root user)'
  exit 1
fi

echo "Start laravel-cli..."

source .env

PROJECT_DIR=$(pwd)
HOME_DIR="/home/user"

USER_ID=$(id -u)
USER_NAME=$(id -un)
GROUP_ID=$(id -g)
GROUP_NAME=$(id -gn)
DOCKER_HOME="${USER_NAME}_docker_home"
docker volume create --name "${DOCKER_HOME}" > /dev/null

docker run -ti --rm \
  -v "${COMPOSE_PROJECT_NAME}_node_modules:/node_modules" \
  -v "${DOCKER_HOME}:${HOME_DIR}" \
  "${LARAVEL_CLI_IMAGE}" bash -c "chown ${USER_ID}:${GROUP_ID} ${HOME_DIR} /node_modules"

mkdir -p "src/node_modules"

START_CLI_FILE=$(mktemp)
trap "rm -f $START_CLI_FILE" 0 2 3 15
cat > "$START_CLI_FILE" <<EOF
#!/bin/bash

getent group ${GROUP_NAME} || groupadd -g ${GROUP_ID} ${GROUP_NAME}

getent passwd ${USER_NAME} || useradd -d ${HOME_DIR} -g ${GROUP_ID} -u ${USER_ID} ${USER_NAME}

su ${USER_NAME} -c "cp -r /etc/skel/. ${HOME_DIR}"
su ${USER_NAME} -c "echo PS1=\'${COMPOSE_PROJECT_NAME}:\\\\\\w\\\\\\\\$ \' >> ${HOME_DIR}/.bashrc"
cd /srv/web

su ${USER_NAME}

EOF

chmod a+x "$START_CLI_FILE"

docker run -ti --rm \
  -v "${PROJECT_DIR}/src:/srv/web" \
  -v "${COMPOSE_PROJECT_NAME}_node_modules:/srv/web/node_modules" \
  -v "${START_CLI_FILE}:/usr/bin/start_cli" \
  -v "${DOCKER_HOME}:${HOME_DIR}" \
  -w "/srv/web" \
  --link "${COMPOSE_PROJECT_NAME}_database_1:database" \
  --net "${COMPOSE_PROJECT_NAME}_default" \
  -e "HOME=${HOME_DIR}" \
  "${LARAVEL_CLI_IMAGE}" /usr/bin/start_cli
