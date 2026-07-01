#!/bin/bash

# Source the Frappe environment
source /home/frappe/.bashrc || true
cd /home/frappe/frappe-bench

echo "Starting Frappe application..."

# Determine site name - use Railway public domain if available, otherwise localhost
if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
  SITE_NAME="$RAILWAY_PUBLIC_DOMAIN"
elif [ -n "$RAILWAY_DOMAIN" ]; then
  SITE_NAME="$RAILWAY_DOMAIN"
else
  SITE_NAME="abn.localhost"
fi

# Detect if running on Railway by checking for MySQL environment variables
if [ -n "$MYSQLHOST" ]; then
  echo "Detected Railway MySQL environment"
  DB_HOST="${MYSQLHOST}"
  DB_PORT="${MYSQLPORT:-3306}"
  DB_NAME="${MYSQLDATABASE:-railway}"
  DB_USER="${MYSQLUSER:-root}"
  DB_PASS="${MYSQLPASSWORD:-}"
else
  echo "Using local database (docker-compose)"
  DB_HOST="db"
  DB_PORT="3306"
  DB_NAME="frappe"
  DB_USER="root"
  DB_PASS="admin"
fi

echo "Database: $DB_HOST:$DB_PORT"

# Create common_site_config.json with database configuration
echo "Creating common_site_config.json..."
cat > sites/common_site_config.json <<EOF
{
  "db_type": "mariadb",
  "db_host": "$DB_HOST",
  "db_port": $DB_PORT,
  "db_name": "$DB_NAME",
  "db_user": "$DB_USER",
  "db_password": "$DB_PASS"
}
EOF

# Create site if it doesn't exist
SITE_DIR="sites/$SITE_NAME"
if [ ! -f "$SITE_DIR/site_config.json" ]; then
  echo "Creating site $SITE_NAME..."
  bench new-site --mariadb-root-username="$DB_USER" --mariadb-root-password="$DB_PASS" --admin-password=admin --install-app erpnext --set-default "$SITE_NAME"
else
  # Check if config has broken/old values and fix them
  if grep -q '\${' "$SITE_DIR/site_config.json"; then
    echo "Detected broken configuration, cleaning and recreating site..."
    rm -rf "$SITE_DIR"
    bench new-site --mariadb-root-username="$DB_USER" --mariadb-root-password="$DB_PASS" --admin-password=admin --install-app erpnext --set-default "$SITE_NAME"
  else
    echo "Site $SITE_NAME already exists, updating configuration..."
    cat > "$SITE_DIR/site_config.json" <<EOF
{
  "db_type": "mariadb",
  "db_host": "$DB_HOST",
  "db_port": $DB_PORT,
  "db_name": "$DB_NAME",
  "db_user": "$DB_USER",
  "db_password": "$DB_PASS"
}
EOF
  fi
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
