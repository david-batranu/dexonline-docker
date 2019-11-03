#!/usr/bin/env bash

readonly DIR_SRC="src/dexonline"
readonly URL_DB="https://dexonline.ro/static/download/dex-database.sql.gz"
readonly DIR_DB="db/dex-database.sql.gz"

_clone-src() {
	set -x

	if [[ ! -d "${DIR_SRC}" ]]; then
		git clone git@github.com:dexonline/dexonline.git "${DIR_SRC}"
	fi
}

_download-db() {
	set -x

	if [[ ! -f "${DIR_DB}" ]]; then
		wget -O "${DIR_DB}" "${URL_DB}"
	fi
}

_update-permissions() {
	set -x

	if [ "$(uname)" == "Darwin" ]; then
		sudo chown -R 33:33 src
		sudo chmod -R +a "user:${USER} allow delete,readattr,writeattr,readextattr,writeextattr,readsecurity,writesecurity,chown,list,search,add_file,add_subdirectory,delete_child,file_inherit,directory_inherit" src
	else
		sudo chown 33:33 -R src
		sudo setfacl -R -m "u:33:rwX,u:${USER}:rwX" src
		sudo setfacl -dR -m "u:33:rwX,u:${USER}:rwX" src
	fi
}

_start-containers() {
	set -x

	docker-compose up -d
}

_setup-database() {
	set -x

	docker-compose exec mariadb mysql -uroot -padmin -e "create database dexonline character set utf8mb4"
	docker-compose exec mariadb bash -c "pv /root/db/dex-database.sql.gz | zcat | mysql -uroot -padmin dexonline"
}

_setup-application() {
	set -x

	# First create Config.php from Config.php.sample...
	docker-compose exec httpd bash tools/setup.sh

	# ... then customize it...
	if [ "$(uname)" == "Darwin" ]; then
		sed -i "" "s|DATABASE = 'mysql://root@localhost/dexonline'|DATABASE = 'mysql://root:admin@mariadb/dexonline'|" "${DIR_SRC}/Config.php"
		sed -i "" "s|URL_PREFIX = '/dexonline/www/'|URL_PREFIX = '/'|" "${DIR_SRC}/Config.php"
	else
		sed -i "s|DATABASE = 'mysql://root@localhost/dexonline'|DATABASE = 'mysql://root:admin@mariadb/dexonline'|" "${DIR_SRC}/Config.php"
		sed -i "s|URL_PREFIX = '/dexonline/www/'|URL_PREFIX = '/'|" "${DIR_SRC}/Config.php"
	fi

	# ... and finally run tools/migration.php, which needs a working database
	docker-compose exec httpd bash -c "php tools/migration.php"
}

_sleep() {
	set -x

	echo "Sleeping 10 seconds..."

	sleep 10
}

_all() {
	set -x

	_clone-src
	_download-db
	_update-permissions
	_start-containers

	_sleep

	_setup-database
	_setup-application
}

for task in "$@"; do
    eval "_${task}"

    exit 0
done

_all