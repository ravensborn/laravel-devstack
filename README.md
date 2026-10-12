# laravel-devstack

Docker setup for Laravel API projects, same shape as asiacell-tms: one compose file per environment at the project root, one folder per environment under `docker/`.

```
docker-compose.yml        local development stack
docker/
  local/                  Dockerfile, entrypoint, php.ini, nginx config, .env template
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

First start runs `composer install`, generates `APP_KEY` and runs migrations. The API is then at http://localhost:3000 and http://localhost:3000/up returns 200.

If the project has no `.env`, `docker/local/.env.example` is copied in. It is a normal Laravel `.env` pointed at the `database` and `redis` services, plus a few variables compose reads:

```
COMPOSE_PROJECT_NAME=laravel   # container prefix, change per project
HOST_UID=1000 / HOST_GID=1000  # match your user so files stay yours
APP_PORT=3000                  # nginx
DB_HOST_PORT=3001              # Postgres
REDIS_HOST_PORT=3002           # Redis
REVERB_PORT=3003               # Reverb
```

Compose reads the project's `.env`, so set those there. If the project already has a `.env`, add the lines you need.

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
