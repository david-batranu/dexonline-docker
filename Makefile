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
  docker-compose exec mariadb apt update
  docker-compose exec mariadb apt install pv
	docker-compose exec mariadb mysql -uroot -padmin -e "create database dexonline character set utf8mb4"
	docker-compose exec mariadb bash -c 'pv /root/db/dex-database.sql.gz | zcat | mysql -uroot -padmin dexonline'

setup-application:
  # Customize Config.php before running tools/migration.php, which needs a
  # working database
	sed -i 's|database = mysql://root@localhost/dexonline|database = mysql://root:admin@mariadb/dexonline|' ${DIR_SRC}/dex.conf
  sed -i "s|URL_PREFIX = '/dexonline/www/'|URL_PREFIX = '/'|" src/dexonline/Config.php
  docker-compose exec httpd bash tools/setup.sh
	docker-compose exec httpd bash -c 'php tools/migration.php'

sleep:
	echo "Sleeping 10 seconds..."
	sleep 10
