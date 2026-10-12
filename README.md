# laravel-devstack

Docker setup for Laravel API projects, same shape as asiacell-tms: one compose file per environment at the project root, one folder per environment under `docker/`.

```
docker-compose.yml        local development stack
docker/
  local/                  Dockerfile, entrypoint, php.ini, nginx config
  data/                   Postgres and Redis data, git-ignored
```

`docker-compose.dev.yml` / `docker/dev` and `docker-compose.prod.yml` / `docker/prod` come later.
No Node in the image. This is for API projects.

## Install into a project

Copy `docker-compose.yml` and the `docker/` folder into the Laravel project root, then:

```bash
docker compose up -d --build
```

Or in one go:

```bash
git clone --depth 1 git@github.com:ravensborn/laravel-devstack.git /tmp/devstack \
  && cp -r /tmp/devstack/docker-compose.yml /tmp/devstack/docker . && rm -rf /tmp/devstack
```

The project must have its own `.env`. Point it at the stack's services:

```
DB_CONNECTION=pgsql
DB_HOST=database
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=laravel
REDIS_HOST=redis
```

Compose reads the same `.env`, so these optional lines go there too:

```
COMPOSE_PROJECT_NAME=laravel   # container / image / network prefix, change per project
HOST_UID=1000                  # match your user so files stay yours
HOST_GID=1000
APP_PORT=3000                  # nginx
DB_HOST_PORT=3001              # Postgres on the host
REDIS_HOST_PORT=3002           # Redis on the host
REVERB_PORT=3003               # Reverb on the host
```

First start runs `composer install` and migrations. The API is then at http://localhost:3000 and http://localhost:3000/up returns 200.

## Services

| Service     | What it runs                                            | Host port |
|-------------|---------------------------------------------------------|-----------|
| `nginx`     | nginx:alpine, serves `public/`                          | 3000      |
| `app`       | php-fpm 8.4 + Composer                                  | –         |
| `horizon`   | `php artisan horizon`, or `queue:work` if not installed | –         |
| `scheduler` | `php artisan schedule:work`                             | –         |
| `reverb`    | `php artisan reverb:start`, idles if not installed      | 3003      |
| `database`  | PostgreSQL 18                                           | 3001      |
| `redis`     | Redis (cache, sessions, queue)                          | 3002      |

The project root is mounted at `/var/www` in every app container. Containers run as your host UID/GID.

## Daily use

```bash
docker compose up -d
docker compose logs -f app
docker compose exec app php artisan migrate
docker compose exec app php artisan tinker
docker compose exec app bash
docker compose down            # data stays in docker/data
```

Delete `docker/data` for a clean database.

## Horizon and Reverb

Both services are always defined so the stack works for any project. `horizon` runs Horizon when `laravel/horizon` is in `vendor/`, otherwise a plain `queue:work`. `reverb` runs Reverb when `laravel/reverb` is installed, otherwise idles. After `composer require laravel/horizon laravel/reverb`, run `docker compose restart horizon reverb` and set `BROADCAST_CONNECTION=reverb` in `.env`.
