#!/bin/bash
echo "=== ClickHouse Database Initialization ==="

# Start ClickHouse server in background AS CLICKHOUSE USER
echo "Starting ClickHouse server..."
su -s /bin/bash -c "/usr/bin/clickhouse-server --config-file=/etc/clickhouse-server/config.xml --daemon" clickhouse &

# Function to check if ClickHouse server is ready
wait_for_clickhouse() {
  echo "Waiting for ClickHouse server to be ready..."
  local max_attempts=60
  local attempt=1
  while [ $attempt -le $max_attempts ]; do
    if su -s /bin/bash -c "clickhouse-client --query 'SELECT 1'" clickhouse > /dev/null 2>&1; then
      echo "ClickHouse server is ready"
      return 0
    else
      echo "Waiting for ClickHouse... (attempt $attempt/$max_attempts)"
      sleep 2
      ((attempt++))
    fi
  done
  echo "Error: ClickHouse server did not become ready in time."
  return 1
}

# Execute initialization scripts
execute_init_queries() {
  echo "Executing initialization query scripts..."
  local init_dir="/docker-entrypoint-initdb.d"
  if [ ! -d "$init_dir" ]; then
    echo "Warning: Init directory $init_dir not found"
    return 0
  fi

  for script in "$init_dir"/*.sql; do
    if [ -f "$script" ]; then
      local script_name=$(basename "$script")
      echo "Executing $script_name..."
      
      if su -s /bin/bash -c "clickhouse-client --multiquery < '$script'" clickhouse; then
        echo "$script_name executed successfully"
      else
        echo "Error executing $script_name"
        exit 1
      fi
    fi
  done

  # Clean up any existing status file
  echo "Cleaning up existing ClickHouse processes..."
  pkill -f clickhouse-server || true
  rm -f /var/lib/clickhouse/status
}

# Wait for ClickHouse to be ready
if ! wait_for_clickhouse; then
  echo "Failed to start ClickHouse server. Exiting."
  exit 1
fi

# Execute initialization scripts
execute_init_queries

# Show database status
echo "Database initialization complete. Server status:"
su -s /bin/bash -c "clickhouse-client --query 'SHOW DATABASES'" clickhouse

# Start server in foreground
echo "Starting ClickHouse server in foreground..."
exec su -s /bin/bash -c "/usr/bin/clickhouse-server --config-file=/etc/clickhouse-server/config.xml" clickhouse
