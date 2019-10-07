### Install docker and docker-compose

* https://docs.docker.com/engine/installation/linux/docker-ce/debian/
* https://docs.docker.com/compose/install/


### Clone this repo
```
git clone git@github.com:david-batranu/dexonline-docker.git
cd dexonline-docker
```

### Grab code and database
```
git clone git@github.com:dexonline/dexonline.git src/dexonline
wget -O ./db/dex-database.sql.gz https://dexonline.ro/static/download/dex-database.sql.gz
```

### Make www-data (container user: 33) owner, allow current user to edit
#### Linux:
```
sudo chown 33:33 -R src/dexonline
sudo setfacl -R -m u:33:rwX src/dexonline && sudo setfacl -dR -m u:33:rwX src/dexonline
sudo setfacl -R -m u:$USER:rwX src/dexonline && sudo setfacl -dR -m u:$USER:rwX src/dexonline
```

#### macOS:
```
sudo chown -R 33:33 src/dexonline
sudo chmod -R +a "user:$USER allow delete,readattr,writeattr,readextattr,writeextattr,readsecurity,writesecurity,chown,list,search,add_file,add_subdirectory,delete_child,file_inherit,directory_inherit" src/dexonline
```

### Start containers
```
docker-compose up -d
```

### Setup & import database
```
docker-compose exec mariadb bash
mysql -uroot -padmin -e "create database DEX character set utf8"
zcat /root/db/dex-database.sql.gz | mysql -uroot -padmin DEX
^D
```

### Migrate
```
docker-compose exec httpd bash
tools/setup.sh
php tools/migration.php
^D
```

### Update Config.php
#### Linux
```
sed -i "s|DATABASE = 'mysql://root@localhost/dexonline'|DATABASE = 'mysql://root:admin@mariadb/DEX'|" src/dexonline/Config.php
```

#### macOS
```
sed -i "" "s|DATABASE = 'mysql://root@localhost/dexonline'|DATABASE = 'mysql://root:admin@mariadb/DEX'|" src/dexonline/Config.php
```

And you're done!

### Makefile
Instead of following the above steps, you can also attempt the automated method, via Makefile.
Just clone this repo and run `make`.
