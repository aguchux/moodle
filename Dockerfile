FROM php:8.3-apache

ARG DEBIAN_FRONTEND=noninteractive

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public \
    MOODLE_DATA_ROOT=/var/moodledata \
    MOODLE_CRON_ENABLED=0

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        cron \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
        exif \
        gd \
        intl \
        mbstring \
        pgsql \
        mysqli \
        opcache \
        pdo_mysql \
        pdo_pgsql \
        soap \
        zip \
    ; \
    a2enmod headers rewrite expires; \
    sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf; \
    sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf; \
    sed -ri -e "s!<Directory /var/www/>!<Directory ${APACHE_DOCUMENT_ROOT}/>!g" /etc/apache2/apache2.conf

COPY docker/php.ini /usr/local/etc/php/conf.d/zz-moodle.ini
COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html
COPY . /var/www/html

RUN set -eux; \
    mkdir -p "${MOODLE_DATA_ROOT}"; \
    chown -R www-data:www-data /var/www/html "${MOODLE_DATA_ROOT}"; \
    chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME ["/var/moodledata"]

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
