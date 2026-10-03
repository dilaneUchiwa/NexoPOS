#!/bin/sh
set -e
cd /var/www/html

# Le wizard d'installation de NexoPOS écrit dans .env : on le garantit.
[ -f .env ] || cp .env.example .env
[ -n "$APP_KEY" ] || { grep -q '^APP_KEY=.\+' .env || php artisan key:generate --force; }

# CA du serveur MySQL managé (ex. Aiven) : fournie en PEM via MYSQL_SSL_CA_PEM.
if [ -n "$MYSQL_SSL_CA_PEM" ]; then
    printf '%s\n' "$MYSQL_SSL_CA_PEM" > /etc/ssl/mysql-ca.pem
    export MYSQL_ATTR_SSL_CA=/etc/ssl/mysql-ca.pem
    grep -q '^MYSQL_ATTR_SSL_CA=' .env || echo "MYSQL_ATTR_SSL_CA=/etc/ssl/mysql-ca.pem" >> .env
fi

php artisan storage:link >/dev/null 2>&1 || true
php artisan config:clear >/dev/null 2>&1 || true

# Si la base est déjà installée, appliquer les migrations en attente.
if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    php artisan migrate --force || true
fi

chown -R www-data:www-data storage bootstrap/cache database
chown www-data:www-data .env
exec docker-php-entrypoint "$@"
