#!/bin/bash
set -e

echo "=== ClickHouse Database Initialization ==="
echo "Starting ClickHouse server with custom initialization..."

# --- -------------------------------------------------------------- INITIALIZATION --- #
# --- -------------------------------------------------------------- -------------- --- #

# Start ClickHouse server in background
echo "Starting ClickHouse server..."
/usr/bin/clickhouse-server --config-file=/etc/clickhouse-server/config.d/config.xml --daemon

# Store the PID for cleanup
CLICKHOUSE_PID=$!

# Function to check if ClickHouse server is ready
wait_for_clickhouse() {
  echo "Waiting for ClickHouse server to be ready..."
  local max_attempts=60
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    if clickhouse-client --query "SELECT 1" > /dev/null 2>&1; then
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

# --- ------------------------------------------------------------- TABLES CREATION --- #
# --- ------------------------------------------------------------- --------------- --- #

# Function to execute SQL scripts
execute_init_scripts() {
  echo "Executing initialization scripts..."
  
  # Get all SQL files from init directory, sorted by name
  local init_dir="/docker-entrypoint-initdb.d"
  
  if [ ! -d "$init_dir" ]; then
    echo "Warning: Init directory $init_dir not found"
    return 0
  fi
  
  # Execute SQL files in alphabetical order
  for script in "$init_dir"/*.sql; do
    if [ -f "$script" ]; then
      local script_name=$(basename "$script")
      echo "Executing $script_name..."
      
      if clickhouse-client --multiquery < "$script"; then
        echo "$script_name executed successfully"
      else
        echo "Error executing $script_name"
        echo "Database initialization failed. Stopping container."
        exit 1
      fi
    fi
  done
  
  echo "All initialization scripts executed successfully!"
}

# Function to cleanup on exit
cleanup() {
  echo "🧹 Cleaning up..."
  if [ ! -z "$CLICKHOUSE_PID" ]; then
    kill $CLICKHOUSE_PID 2>/dev/null || true
    wait $CLICKHOUSE_PID 2>/dev/null || true
  fi
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Wait for ClickHouse to be ready
if ! wait_for_clickhouse; then
  echo "Failed to start ClickHouse server. Exiting."
  exit 1
fi

# Execute initialization scripts
execute_init_scripts

# Show database status
echo "Database initialization complete. Server status:"
clickhouse-client --query "SHOW DATABASES"

# --- -------------------------------------------------------- LEAVE SERVER RUNNING --- #
# --- -------------------------------------------------------- -------------------- --- #

echo "ClickHouse is ready to serve requests!"
echo " - HTTP interface: http://localhost:8123"
echo " - Native protocol: localhost:9000"

# Keep the server running in foreground
echo "Switching to foreground mode..."

# Stop the background server
kill $CLICKHOUSE_PID 2>/dev/null || true
wait $CLICKHOUSE_PID 2>/dev/null || true

# Start server in foreground to keep container alive
echo "Starting ClickHouse server in foreground..."
exec /usr/bin/clickhouse-server --config-file=/etc/clickhouse-server/config.xml

