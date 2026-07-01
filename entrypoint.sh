#!/bin/bash
set -e

# Source the Frappe environment
source /home/frappe/.bashrc || true
cd /home/frappe/frappe-bench

echo "Starting Frappe application..."

# Get Railway MySQL credentials (Railway uses RAILWAY_PRIVATE_DOMAIN, MYSQL_* vars)
DB_HOST="${MYSQLHOST:-${RAILWAY_PRIVATE_DOMAIN:-localhost}}"
DB_PORT="${MYSQLPORT:-3306}"
DB_USER="${MYSQLUSER:-root}"
DB_PASSWORD="${MYSQLPASSWORD:-${MYSQL_ROOT_PASSWORD:-}}"

REDIS_HOST="${REDISHOST:-${RAILWAY_PRIVATE_DOMAIN:-localhost}}"
REDIS_PORT="${REDISPORT:-6379}"

# Skip config if in local environment (already configured)
if [ -z "$RAILWAY_PRIVATE_DOMAIN" ]; then
  echo "Using local configuration"
else
  echo "Configuring for Railway: DB=$DB_HOST REDIS=$REDIS_HOST"
  # Configure global site config with database connection
  bench set-config -g db_host "$DB_HOST"
  bench set-config -gp db_port "$DB_PORT"
  bench set-config -g db_user "$DB_USER"
  if [ -n "$DB_PASSWORD" ]; then
    bench set-config -gp db_password "$DB_PASSWORD"
  fi
  bench set-config -g redis_cache "redis://$REDIS_HOST:$REDIS_PORT/1"
  bench set-config -g redis_queue "redis://$REDIS_HOST:$REDIS_PORT/2"
fi

# Set up environment for Nginx
export FRAPPE_SITE_NAME_HEADER=${FRAPPE_SITE_NAME_HEADER:-abn.localhost}
export BACKEND=${BACKEND:-0.0.0.0:8000}
export SOCKETIO=${SOCKETIO:-0.0.0.0:9000}

# Start Gunicorn backend in background
echo "Starting Gunicorn backend on 0.0.0.0:8000..."
bench serve --port 8000 &

BACKEND_PID=$!

# Give backend time to start
sleep 3

# Start Nginx frontend
echo "Starting Nginx frontend..."
exec nginx-entrypoint.sh
