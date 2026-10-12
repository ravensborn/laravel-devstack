#!/bin/bash
# Entrypoint for the local stack. CONTAINER_ROLE selects what the container runs.
set -euo pipefail

role=${CONTAINER_ROLE:-app}

if [ ! -f artisan ]; then
    echo "[entrypoint] /var/www does not contain a Laravel app. Expected the app at ../.. relative to docker/local" >&2
    exit 1
fi

if [ ! -f .env ]; then
    echo "[entrypoint] No .env in the app, copying docker/local/laravel.env"
    cp /devstack/laravel.env .env
fi

# Only the app container installs dependencies; the others share the bind mount and wait.
if [ "$role" = "app" ]; then
    if [ ! -f vendor/autoload.php ]; then
        echo "[entrypoint] Installing composer dependencies ..."
        composer install --no-progress --no-interaction
    fi
    if [ -f package.json ] && [ ! -f public/build/manifest.json ]; then
        echo "[entrypoint] Building frontend assets ..."
        npm install --no-audit --no-fund && npm run build
    fi
else
    waited=0
    while [ ! -f vendor/autoload.php ]; do
        [ "$waited" -eq 0 ] && echo "[entrypoint] Waiting for the app container to install dependencies ..."
        if [ "$waited" -ge 600 ]; then
            echo "[entrypoint] Timed out waiting for vendor/autoload.php" >&2
            exit 1
        fi
        sleep 2; waited=$((waited + 2))
    done
fi

mkdir -p storage/framework/{cache/data,sessions,testing,views} storage/logs bootstrap/cache

case "$role" in
    app)
        if ! grep -qE '^APP_KEY=base64:' .env; then
            echo "[entrypoint] Generating APP_KEY ..."
            php artisan key:generate --force
        fi
        php artisan migrate --force
        php artisan optimize:clear
        php-fpm -D
        exec nginx -g "daemon off;"
        ;;
    horizon)
        if [ -d vendor/laravel/horizon ]; then
            echo "[entrypoint] Running Horizon ..."
            exec php artisan horizon
        fi
        echo "[entrypoint] laravel/horizon not installed, running queue:work instead"
        exec php artisan queue:work --tries=3 --timeout=90
        ;;
    reverb)
        if [ -d vendor/laravel/reverb ]; then
            echo "[entrypoint] Running Reverb ..."
            exec php artisan reverb:start --host=0.0.0.0 --port=8080
        fi
        echo "[entrypoint] laravel/reverb not installed, idling. Run: composer require laravel/reverb"
        exec sleep infinity
        ;;
    scheduler)
        echo "[entrypoint] Running scheduler ..."
        exec php artisan schedule:work
        ;;
    shell)
        exec sleep infinity
        ;;
    *)
        echo "[entrypoint] Unknown CONTAINER_ROLE \"$role\"" >&2
        exit 1
        ;;
esac
