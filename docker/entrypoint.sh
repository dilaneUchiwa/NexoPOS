#!/bin/sh
set -e
cd /var/www/html

# Le wizard d'installation de NexoPOS écrit dans .env : on le garantit.
[ -f .env ] || cp .env.example .env
[ -n "$APP_KEY" ] || { grep -q '^APP_KEY=.\+' .env || php artisan key:generate --force; }

php artisan storage:link >/dev/null 2>&1 || true
php artisan config:clear >/dev/null 2>&1 || true

# Si la base est déjà installée, appliquer les migrations en attente.
if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    php artisan migrate --force || true
fi

chown -R www-data:www-data storage bootstrap/cache
exec docker-php-entrypoint "$@"
