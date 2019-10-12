# Automated setup

URL_DB=https://dexonline.ro/static/download/dex-database.sql.gz
DIR_SRC=src/dexonline

all: clone-src update-permissions start-containers sleep setup-database setup-application

clone-src:
	git clone git@github.com:dexonline/dexonline.git ${DIR_SRC}
	wget -O ./db/dex-database.sql.gz ${URL_DB}

update-permissions:
	sudo chown 33:33 -R src/
	sudo setfacl -R -m u:33:rwX,u:${USER}:rwX ./src
	sudo setfacl -dR -m u:33:rwX,u:${USER}:rwX ./src

start-containers:
	docker-compose up -d

setup-database:
	docker-compose exec mariadb mysql -uroot -padmin -e "create database dexonline character set utf8mb4"
	docker-compose exec mariadb bash -c 'pv /root/db/dex-database.sql.gz | zcat | mysql -uroot -padmin dexonline'

setup-application:
	# First create Config.php from Config.php.sample...
	docker-compose exec httpd bash tools/setup.sh
	# ... then customize it...
	sed -i "s|DATABASE = 'mysql://root@localhost/dexonline'|DATABASE = 'mysql://root:admin@mariadb/dexonline'|" ${DIR_SRC}/Config.php
	sed -i "s|URL_PREFIX = '/dexonline/www/'|URL_PREFIX = '/'|" ${DIR_SRC}/Config.php
	# ... and finally run tools/migration.php, which needs a working database
	docker-compose exec httpd bash -c 'php tools/migration.php'

sleep:
	echo "Sleeping 10 seconds..."
	sleep 10
