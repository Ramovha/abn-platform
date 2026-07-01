#!/usr/bin/env python3
import os
import json
import sys
import shutil

print("=" * 60)
print("FRAPPE CONFIGURATION DEBUG")
print("=" * 60)

# Print all RAILWAY and MYSQL environment variables
print("\nEnvironment Variables:")
for key in sorted(os.environ.keys()):
    if 'RAILWAY' in key or 'MYSQL' in key or 'DB' in key:
        value = os.environ[key]
        # Mask passwords
        if 'PASSWORD' in key or 'PASS' in key:
            value = '***MASKED***'
        print(f"  {key}={value}")

print("\n" + "=" * 60)

# Determine site name
site_name = os.environ.get('RAILWAY_PUBLIC_DOMAIN') or os.environ.get('RAILWAY_DOMAIN') or 'abn.localhost'

# Detect database configuration
db_config = None

# Try individual variables first (with fallback for broken/literal values)
mysqlhost = os.environ.get('MYSQLHOST', '').strip()
if mysqlhost and '${' not in mysqlhost:
    db_config = {
        'db_type': 'mariadb',
        'db_host': mysqlhost,
        'db_port': int(os.environ.get('MYSQLPORT', '3306')),
        'db_name': os.environ.get('MYSQLDATABASE', 'railway'),
        'db_user': os.environ.get('MYSQLUSER', 'root'),
        'db_password': os.environ.get('MYSQLPASSWORD', ''),
    }
    print(f"✓ Using Railway MySQL (via individual vars): {db_config['db_host']}:{db_config['db_port']}")

# Fallback: try to parse MYSQL_URL
if not db_config:
    mysql_url = os.environ.get('MYSQL_URL', '').strip()
    if mysql_url and not mysql_url.startswith('${'):
        try:
            # Parse mysql://user:password@host:port/database
            from urllib.parse import urlparse
            parsed = urlparse(mysql_url)
            db_config = {
                'db_type': 'mariadb',
                'db_host': parsed.hostname or 'localhost',
                'db_port': parsed.port or 3306,
                'db_name': parsed.path.lstrip('/') or 'railway',
                'db_user': parsed.username or 'root',
                'db_password': parsed.password or '',
            }
            print(f"✓ Using Railway MySQL (via URL): {db_config['db_host']}:{db_config['db_port']}")
        except Exception as e:
            print(f"✗ Failed to parse MYSQL_URL: {e}")

# Final fallback: local database
if not db_config:
    db_config = {
        'db_type': 'mariadb',
        'db_host': 'db',
        'db_port': 3306,
        'db_name': 'frappe',
        'db_user': 'root',
        'db_password': 'admin',
    }
    print(f"⚠ Using local database (docker-compose): {db_config['db_host']}:{db_config['db_port']}")
    print(f"⚠ WARNING: No Railway MySQL variables detected!")
    print(f"⚠ To fix: In Railway, ensure MySQL addon is linked to this app service")

# Create sites directory
os.makedirs('sites', exist_ok=True)

# Create common_site_config.json
with open('sites/common_site_config.json', 'w') as f:
    json.dump(db_config, f, indent=2)
print(f"Created common_site_config.json")

# Create/update site directory and config
site_dir = f'sites/{site_name}'
logs_dir = os.path.join(site_dir, 'logs')

# Check for broken config
config_file = os.path.join(site_dir, 'site_config.json')
needs_recreation = False

if os.path.exists(config_file):
    try:
        with open(config_file, 'r') as f:
            content = f.read()
            if '${' in content:
                print(f"Detected broken configuration in {config_file}, will recreate")
                needs_recreation = True
    except:
        pass

if needs_recreation:
    shutil.rmtree(site_dir)
    os.makedirs(site_dir)
    print(f"Cleaned up site directory: {site_dir}")

# Create necessary directories
os.makedirs(site_dir, exist_ok=True)
os.makedirs(logs_dir, exist_ok=True)

# Create site config
with open(config_file, 'w') as f:
    json.dump(db_config, f, indent=2)
print(f"Created {config_file}")

print(f"Site name: {site_name}")
