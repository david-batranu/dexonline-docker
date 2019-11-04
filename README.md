### Install docker and docker-compose

* https://docs.docker.com/engine/installation/linux/docker-ce/debian/
* https://docs.docker.com/compose/install/

Start the `docker` service (some distros start it by default).

### Clone this repo
```sh
git clone git@github.com:david-batranu/dexonline-docker.git
cd dexonline-docker
```

### Grab code and database
```sh
git clone git@github.com:dexonline/dexonline.git src/dexonline
wget -O ./db/dex-database.sql.gz https://dexonline.ro/static/download/dex-database.sql.gz
```

### Make www-data (container user: 33) owner, allow current user to edit
#### Linux:
```sh
sudo chown 33:33 -R src
sudo setfacl -R -m u:33:rwX,u:$USER:rwX src
sudo setfacl -dR -m u:33:rwX,u:$USER:rwX src
```

#### macOS:
```sh
sudo chown -R 33:33 src
sudo chmod -R +a "user:$USER allow delete,readattr,writeattr,readextattr,writeextattr,readsecurity,writesecurity,chown,list,search,add_file,add_subdirectory,delete_child,file_inherit,directory_inherit" src
```

### Start containers
```sh
docker-compose up -d
```

### Setup & import database
```sh
docker-compose exec mariadb bash
mysql -uroot -padmin -e "create database dexonline character set utf8mb4"
pv /root/db/dex-database.sql.gz | zcat | mysql -uroot -padmin dexonline
^D
```

_Note: The last command may take up a couple of minutes to complete._

### Setup the code
```sh
docker-compose exec httpd bash -c 'tools/setup.sh'
```

### Update Config.php
#### Linux
```sh
sed -i "s|DATABASE = 'mysql://root@localhost/dexonline'|DATABASE = 'mysql://root:admin@mariadb/dexonline'|" src/dexonline/Config.php
sed -i "s|URL_PREFIX = '/dexonline/www/'|URL_PREFIX = '/'|" src/dexonline/Config.php
```

#### macOS
```sh
sed -i "" "s|DATABASE = 'mysql://root@localhost/dexonline'|DATABASE = 'mysql://root:admin@mariadb/dexonline'|" src/dexonline/Config.php
sed -i "" "s|URL_PREFIX = '/dexonline/www/'|URL_PREFIX = '/'|" src/dexonline/Config.php
```

### Migrate the database
```sh
docker-compose exec httpd bash -c 'php tools/migration.php'
```

And you're done! Open `localhost` in your browser to access the website.

### `make.sh` script
Instead of following the steps above, you can also try the automated method, via the `make.sh` script.
Just clone this repo and run `./make.sh`.
Use `./make.sh tasks` to get the list of all available tasks, and `./make task1 task2` to run multiple tasks.
