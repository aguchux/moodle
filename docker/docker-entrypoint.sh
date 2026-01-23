#!/usr/bin/env sh
set -eu

: "${MOODLE_DATA_ROOT:=/var/moodledata}"
: "${MOODLE_CRON_ENABLED:=0}"

if [ ! -d "$MOODLE_DATA_ROOT" ]; then
  mkdir -p "$MOODLE_DATA_ROOT"
fi
chown -R www-data:www-data "$MOODLE_DATA_ROOT"

if [ ! -f /var/www/html/config.php ] && [ "${MOODLE_AUTO_CONFIG:-0}" = "1" ]; then
  : "${MOODLE_WWWROOT:?MOODLE_WWWROOT is required when MOODLE_AUTO_CONFIG=1}"
  : "${MOODLE_DB_TYPE:=pgsql}"
  : "${MOODLE_DB_HOST:=db}"
  : "${MOODLE_DB_PORT:=}"
  : "${MOODLE_DB_NAME:=moodle}"
  : "${MOODLE_DB_USER:=moodle}"
  : "${MOODLE_DB_PASS:=moodle}"
  : "${MOODLE_DB_PREFIX:=mdl_}"
  : "${MOODLE_THEME:=}"

  if [ "${MOODLE_DB_TYPE}" = "pgsql" ]; then
    MOODLE_DB_COLLATION_LINE=""
  else
    MOODLE_DB_COLLATION_LINE="  'dbcollation' => 'utf8mb4_unicode_ci',"
  fi

  MOODLE_THEME_LINE=""
  if [ -n "${MOODLE_THEME}" ]; then
    MOODLE_THEME_LINE="\$CFG->theme = '${MOODLE_THEME}';"
  fi

  cat > /var/www/html/config.php <<EOF
<?php
unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = '${MOODLE_DB_TYPE}';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '${MOODLE_DB_HOST}';
\$CFG->dboptions = [
  'dbpersist' => false,
  'dbport' => '${MOODLE_DB_PORT}',
  'dbsocket' => false,
${MOODLE_DB_COLLATION_LINE}
];
\$CFG->dbname    = '${MOODLE_DB_NAME}';
\$CFG->dbuser    = '${MOODLE_DB_USER}';
\$CFG->dbpass    = '${MOODLE_DB_PASS}';
\$CFG->prefix    = '${MOODLE_DB_PREFIX}';

\$CFG->wwwroot  = '${MOODLE_WWWROOT}';
\$CFG->dataroot = '${MOODLE_DATA_ROOT}';
\$CFG->directorypermissions = 02770;

\$CFG->reverseproxy = ${MOODLE_REVERSEPROXY:-false};
\$CFG->sslproxy = ${MOODLE_SSLPROXY:-false};
${MOODLE_THEME_LINE}

require_once(__DIR__ . '/lib/setup.php');
EOF

  chown www-data:www-data /var/www/html/config.php
fi

if [ "$MOODLE_CRON_ENABLED" = "1" ]; then
  echo '* * * * * www-data /usr/local/bin/php /var/www/html/admin/cron.php >/proc/1/fd/1 2>/proc/1/fd/2' > /etc/cron.d/moodle
  chmod 0644 /etc/cron.d/moodle
  crontab /etc/cron.d/moodle
  cron
fi

exec "$@"
