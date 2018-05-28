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
	docker-compose exec mariadb mysql -uroot -padmin -e "create database DEX character set utf8"
	docker-compose exec mariadb bash -c 'zcat /root/db/dex-database.sql.gz | mysql -uroot -padmin DEX'

setup-application:
	docker-compose exec httpd bash tools/setup.sh
	docker-compose exec httpd bash -c 'php tools/migration.php'
	sed -i 's|database = mysql://root@localhost/DEX|database = mysql://root:admin@mariadb/DEX|' ${DIR_SRC}/dex.conf

sleep:
	echo "Sleeping 10 seconds..."
	sleep 10
