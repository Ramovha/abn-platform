#!/bin/bash

# Source the Frappe environment
source /home/frappe/.bashrc || true
cd /home/frappe/frappe-bench

echo "Starting Frappe application..."

# Determine site name - use Railway domain if available, otherwise localhost
if [ -n "$RAILWAY_DOMAIN" ]; then
  SITE_NAME="$RAILWAY_DOMAIN"
else
  SITE_NAME="abn.localhost"
fi

# Create site if it doesn't exist
SITE_DIR="sites/$SITE_NAME"
if [ ! -f "$SITE_DIR/site_config.json" ]; then
  echo "Creating site $SITE_NAME..."
  bench new-site --mariadb-root-username=root --mariadb-root-password=admin --admin-password=admin --install-app erpnext --set-default "$SITE_NAME"
else
  echo "Site $SITE_NAME already exists"
fi

# Set up environment for Nginx
export FRAPPE_SITE_NAME_HEADER="$SITE_NAME"
export BACKEND=${BACKEND:-0.0.0.0:8000}
export SOCKETIO=${SOCKETIO:-0.0.0.0:9000}

echo "Using site: $SITE_NAME"

# Start Gunicorn backend in background
echo "Starting Gunicorn backend on 0.0.0.0:8000..."
bench serve --port 8000 &

BACKEND_PID=$!

# Give backend time to start
sleep 3

# Start Nginx frontend
echo "Starting Nginx frontend..."
exec nginx-entrypoint.sh
