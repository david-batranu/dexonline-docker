FROM php:7.4-apache
RUN apt update && apt install -y mysql-client && apt-get clean
RUN docker-php-ext-install -j$(nproc) gettext mysqli pdo_mysql && a2enmod rewrite
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
