#!/bin/bash
set -e

FRAPPE_BENCH=/home/frappe/frappe-bench
FRAPPE_ENV=${FRAPPE_BENCH}/env/bin/activate

# Activate the Frappe virtual environment so gunicorn and bench are in PATH
if [ -f "${FRAPPE_ENV}" ]; then
    # shellcheck disable=SC1090
    source "${FRAPPE_ENV}"
else
    echo "ERROR: Frappe virtual environment not found at ${FRAPPE_ENV}" >&2
    exit 1
fi

cd "${FRAPPE_BENCH}"

echo "Starting Frappe application..."

# Set up environment
export FRAPPE_SITE_NAME_HEADER=${FRAPPE_SITE_NAME_HEADER:-abn.localhost}
export BACKEND=${BACKEND:-backend:8000}
export SOCKETIO=${SOCKETIO:-websocket:9000}

# Resolve gunicorn — prefer the venv binary, fall back to PATH
GUNICORN_BIN="${FRAPPE_BENCH}/env/bin/gunicorn"
if [ ! -x "${GUNICORN_BIN}" ]; then
    GUNICORN_BIN=$(command -v gunicorn 2>/dev/null || true)
fi
if [ -z "${GUNICORN_BIN}" ]; then
    echo "ERROR: gunicorn not found in ${FRAPPE_BENCH}/env/bin or PATH" >&2
    exit 1
fi

# Number of Gunicorn workers (default 2, override via GUNICORN_WORKERS env var)
WORKERS=${GUNICORN_WORKERS:-2}

# Start Gunicorn backend in background
echo "Starting Gunicorn backend on 0.0.0.0:8000 with ${WORKERS} workers..."
"${GUNICORN_BIN}" \
    --bind 0.0.0.0:8000 \
    --workers "${WORKERS}" \
    --worker-class gthread \
    --threads 4 \
    --timeout 120 \
    --preload \
    frappe.app:application &

BACKEND_PID=$!

# Wait for Gunicorn to be ready before starting Nginx
echo "Waiting for Gunicorn to be ready..."
for i in $(seq 1 30); do
    if kill -0 "${BACKEND_PID}" 2>/dev/null && \
       (echo > /dev/tcp/127.0.0.1/8000) 2>/dev/null; then
        echo "Gunicorn is ready."
        break
    fi
    if ! kill -0 "${BACKEND_PID}" 2>/dev/null; then
        echo "ERROR: Gunicorn process exited unexpectedly." >&2
        exit 1
    fi
    echo "  waiting... (${i}/30)"
    sleep 2
done

# Start Nginx frontend (takes over as PID 1 via exec)
echo "Starting Nginx frontend..."
exec nginx-entrypoint.sh
