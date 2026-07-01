#!/bin/bash
set -e

echo "Starting Frappe application..."

# Set up environment
export FRAPPE_SITE_NAME_HEADER=${FRAPPE_SITE_NAME_HEADER:-abn.localhost}
export BACKEND=${BACKEND:-0.0.0.0:8000}
export SOCKETIO=${SOCKETIO:-0.0.0.0:9000}

# Start Gunicorn backend in background
echo "Starting Gunicorn backend..."
gunicorn \
  --bind 0.0.0.0:8000 \
  --workers 4 \
  --threads 2 \
  --worker-class gthread \
  --timeout 120 \
  frappe.wsgi:application &

GUNICORN_PID=$!

# Start Nginx frontend
echo "Starting Nginx frontend..."
exec nginx-entrypoint.sh
