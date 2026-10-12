# Local development image for a Laravel API (PHP 8.4). No Node/npm on purpose.
# nginx + php-fpm in one container; the app source is bind-mounted at /var/www.
FROM php:8.4-fpm

ARG UID=1000
ARG GID=1000

ENV HOME=/home/dev \
    COMPOSER_HOME=/home/dev/.composer \
    XDG_CONFIG_HOME=/home/dev/.config \
    XDG_CACHE_HOME=/home/dev/.cache \
    PATH=/var/www/vendor/bin:$PATH \
    PHP_OPCACHE_ENABLE=1 \
    PHP_OPCACHE_ENABLE_CLI=0 \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=1 \
    PHP_OPCACHE_REVALIDATE_FREQ=0

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git less procps unzip zip nginx \
        libpq-dev libonig-dev libzip-dev libpng-dev libjpeg-dev libwebp-dev libfreetype6-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --enable-gd --with-jpeg --with-webp --with-freetype \
    && docker-php-ext-install -j"$(nproc)" pdo_pgsql pdo_mysql bcmath mbstring opcache exif gd zip pcntl \
    && pecl install redis \
    && docker-php-ext-enable redis

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY config/php.ini      /usr/local/etc/php/php.ini
COPY config/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY config/nginx.conf   /etc/nginx/nginx.conf
COPY config/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && mkdir -p /var/cache/nginx /var/log/nginx /run /var/lib/nginx \
    && if [ "$(getent group "${GID}" | cut -d: -f1)" != 'www-data' ]; then groupmod --gid "${GID}" www-data; fi \
    && if [ "$(id -u www-data)" != "${UID}" ]; then usermod --uid "${UID}" www-data; fi \
    && usermod --gid "${GID}" --home /home/dev --shell /bin/bash www-data \
    && mkdir -p /home/dev/.composer /home/dev/.config /home/dev/.cache /var/www \
    && chown -R "${UID}:${GID}" /home/dev /var/www /var/cache/nginx /var/log/nginx /run /var/lib/nginx \
    && git config --system --add safe.directory /var/www

WORKDIR /var/www
USER www-data

ENTRYPOINT ["/entrypoint.sh"]
