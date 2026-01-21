# Moodle Docker image (Apache + PHP)

This repository includes a basic `Dockerfile` suitable for building a Moodle runtime image for Docker Hub.

## Build

```bash
docker build -t your-org/moodle:local .
```

## Run (bring your own `config.php`)

Moodle expects `config.php` at the repo root (`/var/www/html/config.php`) and a writable `dataroot`.

```bash
docker run --rm -p 8080:80 ^
  -v ${PWD}\config.php:/var/www/html/config.php ^
  -v moodledata:/var/moodledata ^
  your-org/moodle:local
```

## Run (auto-generate `config.php`)

Set `MOODLE_AUTO_CONFIG=1` and provide DB + `wwwroot` settings.

```bash
docker run --rm -p 8080:80 ^
  -e MOODLE_AUTO_CONFIG=1 ^
  -e MOODLE_WWWROOT=http://localhost:8080 ^
  -e MOODLE_DB_TYPE=pgsql ^
  -e MOODLE_DB_HOST=db ^
  -e MOODLE_DB_NAME=moodle ^
  -e MOODLE_DB_USER=moodle ^
  -e MOODLE_DB_PASS=moodle ^
  -v moodledata:/var/moodledata ^
  your-org/moodle:local
```

## Cron

Enable the built-in cron runner (runs `admin/cron.php` every minute):

```bash
docker run --rm -p 8080:80 ^
  -e MOODLE_CRON_ENABLED=1 ^
  -v ${PWD}\config.php:/var/www/html/config.php ^
  -v moodledata:/var/moodledata ^
  your-org/moodle:local
```
