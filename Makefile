# Automated setup

DIR_SRC=src/dexonline
URL_DB=https://dexonline.ro/static/download/dex-database.sql.gz
DIR_DB=db/dex-database.sql.gz

all: clone-src download-db update-permissions start-containers sleep setup-database setup-application

clone-src:
ifeq (,$(wildcard ${DIR_SRC}))
	git clone git@github.com:dexonline/dexonline.git ${DIR_SRC}
endif

download-db:
ifeq (,$(wildcard ${DIR_DB}))
	wget -O ${DIR_DB} ${URL_DB}
endif

update-permissions:
ifeq ($(OS),Windows_NT)
	sudo chown 33:33 -R src
	sudo setfacl -R -m u:33:rwX,u:${USER}:rwX src
	sudo setfacl -dR -m u:33:rwX,u:${USER}:rwX src
else
	sudo chown -R 33:33 src
	sudo chmod -R +a "user:${USER} allow delete,readattr,writeattr,readextattr,writeextattr,readsecurity,writesecurity,chown,list,search,add_file,add_subdirectory,delete_child,file_inherit,directory_inherit" src
endif

start-containers:
	docker-compose up -d

setup-database:
	docker-compose exec mariadb mysql -uroot -padmin -e "create database dexonline character set utf8mb4"
	docker-compose exec mariadb bash -c 'pv /root/db/dex-database.sql.gz | zcat | mysql -uroot -padmin dexonline'

setup-application:
	# First create Config.php from Config.php.sample...
	docker-compose exec httpd bash tools/setup.sh
	# ... then customize it...
ifeq ($(OS),Windows_NT)
	sed -i "s|DATABASE = 'mysql://root@localhost/dexonline'|DATABASE = 'mysql://root:admin@mariadb/dexonline'|" ${DIR_SRC}/Config.php
	sed -i "s|URL_PREFIX = '/dexonline/www/'|URL_PREFIX = '/'|" ${DIR_SRC}/Config.php
else
	sed -i "" "s|DATABASE = 'mysql://root@localhost/dexonline'|DATABASE = 'mysql://root:admin@mariadb/dexonline'|" ${DIR_SRC}/Config.php
	sed -i "" "s|URL_PREFIX = '/dexonline/www/'|URL_PREFIX = '/'|" ${DIR_SRC}/Config.php
endif
	# ... and finally run tools/migration.php, which needs a working database
	docker-compose exec httpd bash -c 'php tools/migration.php'

sleep:
	echo "Sleeping 10 seconds..."
	sleep 10
