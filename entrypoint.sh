#!/bin/bash
set -e

# Source the Frappe environment
source /home/frappe/.bashrc || true
cd /home/frappe/frappe-bench

echo "Starting Frappe application..."

# Configure global site config with database connection
bench set-config -g db_host "${MYSQLHOST:-localhost}"
bench set-config -gp db_port "${MYSQLPORT:-3306}"
bench set-config -g db_user "${MYSQLUSER:-root}"
bench set-config -gp db_password "${MYSQLPASSWORD:-}"
bench set-config -g redis_cache "redis://${REDISHOST:-localhost}:${REDISPORT:-6379}/1"
bench set-config -g redis_queue "redis://${REDISHOST:-localhost}:${REDISPORT:-6379}/2"

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
