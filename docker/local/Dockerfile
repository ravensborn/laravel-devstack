# syntax=docker/dockerfile:1.7
# Local development image for a Laravel API. php-fpm only; nginx runs in its own container.
FROM php:8.4-fpm-bookworm

ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/app \
    COMPOSER_HOME=/home/app/.composer \
    PATH=/var/www/vendor/bin:$PATH

# 1. System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
        git curl ca-certificates unzip zip \
        libpq-dev libzip-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
        libonig-dev libxml2-dev libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. PHP extensions (Postgres + Redis + everything Laravel/Horizon needs)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        pdo pdo_pgsql pgsql pdo_mysql \
        mbstring exif pcntl bcmath gd zip intl opcache \
    && pecl install redis \
    && docker-php-ext-enable redis

# 3. Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. App user that matches host UID/GID; align php-fpm to it
RUN groupadd -g ${GID} app \
    && useradd -u ${UID} -g ${GID} -m -d /home/app -s /bin/bash app \
    && mkdir -p /home/app/.composer \
    && chown -R ${UID}:${GID} /home/app \
    && sed -i "s/^user = www-data/user = app/"  /usr/local/etc/php-fpm.d/www.conf \
    && sed -i "s/^group = www-data/group = app/" /usr/local/etc/php-fpm.d/www.conf \
    && git config --system --add safe.directory /var/www

# 5. PHP overrides
COPY php.ini /usr/local/etc/php/conf.d/zz-app.ini

WORKDIR /var/www

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
