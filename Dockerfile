# Base image
FROM php:7.4.9-apache

# Base system dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y \
    curl \
    git \
  && rm -rf /var/lib/apt/lists/*

# Apache extension - rewrite
RUN a2enmod rewrite

# PHP extension - memcached
RUN apt-get update \
  && apt-get install -y \
    libmemcached-dev \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/* \
  && pecl install memcached \
  && docker-php-ext-enable memcached

# PHP extension - zip
RUN apt-get update \
  && apt-get install -y \
    libzip-dev \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/* \
  && docker-php-ext-install zip

# Composer
RUN curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer \
  && composer global require hirak/prestissimo

# Application files
ADD composer.json composer.lock /application/
WORKDIR /application
RUN composer install --no-interaction --no-scripts --quiet \
  && cp -R /application/vendor/clickalicious/phpmemadmin/app /application/ \
  && cp -R /application/vendor/clickalicious/phpmemadmin/bin /application/ \
  && cp -R /application/vendor/clickalicious/phpmemadmin/web /application/
ADD config.json /application/app/.config

# Volumes mapping
VOLUME ["/application/vendor"]

# Apache configuration
ADD apache.conf /etc/apache2/sites-available/phpmemadmin.conf
RUN a2dissite 000-default.conf \
  && a2ensite phpmemadmin.conf

# Symbolic link for Apache
RUN rm -rf /var/www/html \
  && ln -s /application/web /var/www/html

# Expose ports
EXPOSE 80

# Healthcheck
ADD ./docker-healthcheck.sh /usr/local/bin/docker-healthcheck
RUN chmod +x /usr/local/bin/docker-healthcheck
HEALTHCHECK CMD docker-healthcheck
