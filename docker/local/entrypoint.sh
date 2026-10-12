#!/usr/bin/env bash
set -e

cd /var/www

if [ ! -f artisan ]; then
    echo "/var/www is not a Laravel app. docker-compose.yml must sit in the project root." >&2
    exit 1
fi

if [ ! -f .env ]; then
    echo "No .env found, copying docker/local/.env.example"
    cp docker/local/.env.example .env
fi

mkdir -p storage/framework/{cache/data,sessions,testing,views} storage/logs bootstrap/cache

# Workers need composer deps, which the app container installs.
wait_for_vendor() {
    until [ -f vendor/autoload.php ]; do
        echo "Waiting for composer install to finish..."
        sleep 3
    done
}

case "${CONTAINER_ROLE:-app}" in
    app)
        if [ ! -f vendor/autoload.php ]; then
            composer install --no-progress --no-interaction
        fi
        if ! grep -qE '^APP_KEY=base64:' .env; then
            php artisan key:generate --force
        fi
        php artisan optimize:clear
        php artisan migrate --force
        exec php-fpm -F
        ;;

    horizon)
        wait_for_vendor
        if [ -d vendor/laravel/horizon ]; then
            exec php artisan horizon
        fi
        echo "laravel/horizon not installed, running queue:work instead"
        exec php artisan queue:work --tries=3 --timeout=90
        ;;

    scheduler)
        wait_for_vendor
        exec php artisan schedule:work
        ;;

    reverb)
        wait_for_vendor
        if [ -d vendor/laravel/reverb ]; then
            exec php artisan reverb:start --host=0.0.0.0 --port=8080
        fi
        echo "laravel/reverb not installed, idling. Run: composer require laravel/reverb"
        exec sleep infinity
        ;;

    *)
        echo "Unknown CONTAINER_ROLE \"${CONTAINER_ROLE}\""
        exit 1
        ;;
esac
