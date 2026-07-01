#!/bin/bash

# Source the Frappe environment
source /home/frappe/.bashrc || true
cd /home/frappe/frappe-bench

echo "Starting Frappe application..."

# Run Python script to configure Frappe
python3 /configure_frappe.py

# Get site name from Python script output
SITE_NAME=$(python3 -c "import os; print(os.environ.get('RAILWAY_PUBLIC_DOMAIN') or os.environ.get('RAILWAY_DOMAIN') or 'abn.localhost')")
DB_USER=${MYSQLUSER:-root}
DB_PASS=${MYSQLPASSWORD:-admin}

# Create site if it doesn't exist
SITE_DIR="sites/$SITE_NAME"
if [ ! -f "$SITE_DIR/site_config.json" ]; then
  echo "Creating site $SITE_NAME..."
  bench new-site --mariadb-root-username="$DB_USER" --mariadb-root-password="$DB_PASS" --admin-password=admin --install-app erpnext --set-default "$SITE_NAME"
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
