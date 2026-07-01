#!/bin/bash

# Source the Frappe environment
source /home/frappe/.bashrc || true
cd /home/frappe/frappe-bench

echo "Starting Frappe application..."

# Create site if it doesn't exist
SITE_DIR="sites/abn.localhost"
if [ ! -f "$SITE_DIR/site_config.json" ]; then
  echo "Creating site abn.localhost..."
  bench new-site --mariadb-root-username=root --mariadb-root-password=admin --admin-password=admin --install-app erpnext --set-default abn.localhost
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
