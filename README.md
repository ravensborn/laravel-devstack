# laravel-devstack

Reusable Docker Compose stack for running any Laravel app locally. Point it at a project, run `docker compose up`, done.
Local development only; not meant for production.

## Services

| Service     | What it runs                                            | Host port |
|-------------|---------------------------------------------------------|-----------|
| `app`       | nginx + php-fpm (PHP 8.4, Node 22, Composer)            | 3000      |
| `horizon`   | `php artisan horizon`, or `queue:work` if not installed | –         |
| `reverb`    | `php artisan reverb:start`, idles if not installed      | 3003      |
| `scheduler` | `php artisan schedule:work`                             | –         |
| `database`  | PostgreSQL 18                                           | 3001      |
| `redis`     | Redis (cache, sessions, queue)                          | 3002      |

The app source is bind-mounted into the containers, so edits on the host apply immediately.
Containers run as your host UID/GID, so files they create are owned by you.

## Setup

```bash
git clone git@github.com:ravensborn/laravel-devstack.git
cd laravel-devstack

cp .env.example .env
# set PROJECT_NAME and APP_PATH, adjust ports if they clash

docker compose up -d --build
```

First start takes a few minutes: it runs `composer install`, `npm run build`, generates `APP_KEY`, and runs migrations.
When it is done the app is at http://localhost:3000 and http://localhost:3000/up returns 200.

If the app has no `.env`, `env/.env.app` is copied in automatically. After that, edit the app's `.env`, not the template.

## Running several projects

One clone of this repo serves one project at a time (the `.env` picks it). To run two projects side by side, clone it twice with different `PROJECT_NAME` and ports.

## Daily use

```bash
docker compose up -d                       # start
docker compose logs -f app                 # follow logs
docker compose exec app php artisan migrate
docker compose exec app php artisan tinker
docker compose exec app bash               # shell in the app container
docker compose down                        # stop (data is kept in ./data)
docker compose down -v                     # also drop the composer/npm cache volume
```

Database and Redis data live in `./data/` (git-ignored). Delete that folder for a clean slate.

## Horizon and Reverb

Both services are always defined so the stack works for any project:

- `horizon` runs Horizon when `laravel/horizon` is in `vendor/`, otherwise a plain `queue:work`.
- `reverb` runs Reverb when `laravel/reverb` is in `vendor/`, otherwise it idles with a log message.

To enable them in a project: `composer require laravel/horizon laravel/reverb`, then `docker compose restart horizon reverb`.
`env/.env.app` already has the Reverb variables; set `BROADCAST_CONNECTION=reverb` in the app's `.env`.

## Layout

```
docker-compose.yml   services
Dockerfile           PHP 8.4 fpm + nginx + node + composer
docker/              nginx, php, php-fpm config and the entrypoint
env/.env.app         Laravel .env template for the containers
.env.example         compose variables (project name, path, ports, credentials)
```
