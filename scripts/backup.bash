#!/bin/bash -x
set -eou pipefail

_create_backup() {
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    printf "%s\n" "ERROR : Git repository not detected. Exiting." 2>&1
    exit 3
  else
    local git_toplevel=$(git rev-parse --show-toplevel)
  fi

  local backup_time=$(date +%s-%Y-%m-%d)
  local maintenance_message="\$wgReadOnly = 'Backing up database. Write access will be restored shortly...';"

  # Lock database writes
  printf "%s\n" "INFO : Setting the wiki into read-only mode - $(date +%s)..."
  if ! docker exec -it web grep -E '^\$wgReadOnly' /var/www/html/LocalSettings.php >/dev/null; then
    docker exec -it web /bin/bash -c "echo '$maintenance_message' >> /var/www/html/LocalSettings.php"
  fi

  # Retrieve data from mariadb
  printf "%s\n" "INFO : Copying files from mariadb..."
  docker exec -it db /bin/bash -c "mysqldump --column-statistics=0 -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} >/wiki.sql"
  docker cp db:/wiki.sql ${git_toplevel}/backups/wiki.sql

  # Retrieve data from mediawiki
  printf "%s\n" "INFO : Copying files from mediawiki..."
  rm -rf ${git_toplevel}/backups/html
  docker cp web:/var/www/html ${git_toplevel}/backups
 
  # Unlock database writes
  printf "%s\n" "INFO : Setting the wiki out of read-only mode - $(date +%s)..."
  if docker exec -it web grep -E '^\$wgReadOnly' /var/www/html/LocalSettings.php >/dev/null; then
    docker exec -it web sed -i '/^\$wgReadOnly.*$/d' /var/www/html/LocalSettings.php
  fi

  # Create tarball
  printf "%s\n" "INFO : Creating backup tarball '${backup_time}-nexus-wiki.org.tar.gz' with latest contents..."
  sed -i '/^\$wgReadOnly.*$/d' ${git_toplevel}/backups/html/LocalSettings.php
  tar -C ${git_toplevel}/backups -czf ${git_toplevel}/backups/${backup_time}-nexus-wiki.org.tar.gz wiki.sql html
}

_rotate_local_backups() {
  local num_local_backups='5'

  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    printf "%s\n" "ERROR : Git repository not detected. Exiting."
    exit 3
  else
    local git_toplevel=$(git rev-parse --show-toplevel)
  fi

  # Keep five local backups
  while [ $(ls ${git_toplevel}/backups | grep nexus-wiki.org.tar.gz$ | wc -l) -gt ${num_local_backups} ]; do
    printf "%s\n" "INFO : More than ${num_local_backups} local backups. Removing $(ls ${git_toplevel}/backups | grep nexus-wiki.org.tar.gz$ | head -n 1)..."
    # Delete alphabetically oldest file (ls sort by name is default)
    rm ${git_toplevel}/backups/$(ls ${git_toplevel}/backups | grep nexus-wiki.org.tar.gz$ | head -n 1)
  done
}

_create_backup
_rotate_local_backups

printf "%s\n" "INFO : Nexus Wiki backup finished successfully"
