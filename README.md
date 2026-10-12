# laravel-devstack

Docker configs for Laravel API projects (no Node/npm in the image), one folder per environment. Copy this repo into a project as `docker/` and run the environment you need from its folder.

```
docker/
  local/   local development stack (this is all there is for now)
  prod/    coming later
```

## Local

Services, all prefixed with `PROJECT_NAME` from `local/.env`:

| Service     | What it runs                                            | Host port |
|-------------|---------------------------------------------------------|-----------|
| `app`       | nginx + php-fpm (PHP 8.4, Composer)                     | 3000      |
| `horizon`   | `php artisan horizon`, or `queue:work` if not installed | –         |
| `reverb`    | `php artisan reverb:start`, idles if not installed      | 3003      |
| `scheduler` | `php artisan schedule:work`                             | –         |
| `database`  | PostgreSQL 18                                           | 3001      |
| `redis`     | Redis (cache, sessions, queue)                          | 3002      |

The project root is bind-mounted into the containers, so edits on the host apply immediately. Containers run as your host UID/GID, so files they create are owned by you.

### Setup

```bash
# inside your Laravel project
git clone --depth 1 git@github.com:ravensborn/laravel-devstack.git docker && rm -rf docker/.git

cd docker/local
cp .env.example .env     # set PROJECT_NAME, change ports if they clash
docker compose up -d --build
```

First start takes a few minutes: `composer install`, `APP_KEY` generation and migrations run automatically.
Then the app is at http://localhost:3000 and http://localhost:3000/up returns 200.

If the project has no `.env`, `local/laravel.env` is copied in (PostgreSQL + Redis, service hostnames). After that, edit the project's `.env`, not the template.

`local/.gitignore` keeps `.env` and `data/` out of the project's git. Commit the rest of `docker/` with the project.

### Daily use

Run these from `docker/local`:

```bash
docker compose up -d                       # start
docker compose logs -f app                 # follow logs
docker compose exec app php artisan migrate
docker compose exec app php artisan tinker
docker compose exec app bash               # shell in the app container
docker compose down                        # stop (data is kept in ./data)
docker compose down -v                     # also drop the composer cache volume
```

Database and Redis data live in `local/data/`. Delete that folder for a clean slate.

### Horizon and Reverb

Both services are always defined so the stack works for any project:

- `horizon` runs Horizon when `laravel/horizon` is in `vendor/`, otherwise a plain `queue:work`.
- `reverb` runs Reverb when `laravel/reverb` is in `vendor/`, otherwise it idles with a log message.

To enable them: `composer require laravel/horizon laravel/reverb`, then `docker compose restart horizon reverb`.
`laravel.env` already has the Reverb variables; set `BROADCAST_CONNECTION=reverb` in the project's `.env`.

### Layout

```
local/
  docker-compose.yml   services
  Dockerfile           PHP 8.4 fpm + nginx + composer (no Node, API projects only)
  config/              nginx, php, php-fpm config and the entrypoint
  laravel.env          Laravel .env template for the containers
  .env.example         compose variables (project name, ports, credentials)
```
