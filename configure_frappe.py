#!/usr/bin/env python3
import os
import json
import sys

# Determine site name
site_name = os.environ.get('RAILWAY_PUBLIC_DOMAIN') or os.environ.get('RAILWAY_DOMAIN') or 'abn.localhost'

# Detect database configuration
if os.environ.get('MYSQLHOST'):
    db_config = {
        'db_type': 'mariadb',
        'db_host': os.environ.get('MYSQLHOST'),
        'db_port': int(os.environ.get('MYSQLPORT', '3306')),
        'db_name': os.environ.get('MYSQLDATABASE', 'railway'),
        'db_user': os.environ.get('MYSQLUSER', 'root'),
        'db_password': os.environ.get('MYSQLPASSWORD', ''),
    }
    print(f"Using Railway MySQL: {db_config['db_host']}:{db_config['db_port']}")
else:
    db_config = {
        'db_type': 'mariadb',
        'db_host': 'db',
        'db_port': 3306,
        'db_name': 'frappe',
        'db_user': 'root',
        'db_password': 'admin',
    }
    print(f"Using local database: {db_config['db_host']}:{db_config['db_port']}")

# Create common_site_config.json
os.makedirs('sites', exist_ok=True)
with open('sites/common_site_config.json', 'w') as f:
    json.dump(db_config, f, indent=2)
print(f"Created common_site_config.json")

# Create/update site directory and config
site_dir = f'sites/{site_name}'
os.makedirs(site_dir, exist_ok=True)

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
    import shutil
    shutil.rmtree(site_dir)
    os.makedirs(site_dir)
    print(f"Cleaned up site directory: {site_dir}")

# Create site config
with open(config_file, 'w') as f:
    json.dump(db_config, f, indent=2)
print(f"Created {config_file}")

print(f"Site name: {site_name}")
