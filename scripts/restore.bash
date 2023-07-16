#!/bin/bash -x
set -eou pipefail

_restore_latest_backup() {
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    printf "%s\n" "ERROR : Git repository not detected. Exiting."
    exit 3
  else
    local git_toplevel=$(git rev-parse --show-toplevel)
  fi

  local cwd=$(pwd)
  local latest_backup=${git_toplevel}/backups/$(ls ${git_toplevel}/backups | grep nexus-wiki.org.tar.gz$ | tail -n 1)

  if [ ! -f "${latest_backup}" ]; then
    printf "%s\n" "ERROR : no tarball found in backups directory. Exiting." 2>&1
    exit 3
  fi

  cd ${git_toplevel}/backups
  tar -zxf "${latest_backup}"
  if [ ! -d ${git_toplevel}/backups/html ] || [ ! -f ${git_toplevel}/backups/wiki.sql ]; then
    printf "%s\n" "ERROR : no files found in backups directory. Exiting." 2>&1
    exit 3
  fi

  # Reset docker compose
  cd ${git_toplevel}
  docker compose down
  local images=$(docker images wiki-web -q && true)
  if [ ! -z "${images}" ]; then
    docker image rm ${images} >/dev/null 2>&1
  fi
  local volumes=$(docker volume ls -q && true)
  if [ ! -z "${volumes}" ]; then
    docker volume rm ${volumes} >/dev/null 2>&1
  fi
  docker compose up -d --build --remove-orphans

  # Retrieve data for mariadb
  printf "%s\n" "INFO : Copying files for mariadb..."
  docker exec -it db /bin/bash -c "apt -yqq update && apt -yqq install mysql-client"
  docker cp ${git_toplevel}/backups/wiki.sql db:/
  docker exec -it db /bin/bash -c "mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} </wiki.sql"

  # Retrieve data for mediawiki
  printf "%s\n" "INFO : Copying files for mediawiki..."
  while read file; do
    docker cp ${git_toplevel}/backups/html/${file} web:/var/www/html >/dev/null 2>&1
  done <<< "$(ls -A ${git_toplevel}/backups/html)"

  cd "${cwd}"
}

_restore_latest_backup

printf "%s\n" "INFO : Nexus Wiki restore finished successfully"
