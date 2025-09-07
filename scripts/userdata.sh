
#!/bin/bash
# File: scripts/userdata.sh
# Purpose: Install Docker, Docker Compose and deploy services

set -e

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /var/log/infradex-setup.log
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting Infradex infrastructure setup..."

# Update system
log "Updating system packages..."
yum update -y

# Install required packages
log "Installing essential packages..."
yum install -y git curl wget unzip docker

# Start and enable Docker
log "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install Docker Compose
log "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create application directory
log "Setting up application directories..."
mkdir -p /opt/infradex/{docker,logs,data}
cd /opt/infradex

# Clone the repository (or copy files)
log "Setting up Docker environment..."
# Note: In production, you'd copy the docker files during terraform deployment
# For now, we'll create the structure manually

# Create docker-compose.yml for the actual services we need
cat <<'EOF' > /opt/infradex/docker-compose.yml
version: '3.8'

services:
  # ClickHouse Database Service
  database:
    build:
      context: .
      dockerfile: database.Dockerfile
    container_name: infradex-clickhouse
    ports:
      - "8123:8123"  # HTTP interface
      - "9000:9000"  # Native protocol
    volumes:
      - clickhouse_data:/var/lib/clickhouse
      - ./clickhouse/config.xml:/etc/clickhouse-server/config.xml
      - ./clickhouse/users.xml:/etc/clickhouse-server/users.xml
    environment:
      - CLICKHOUSE_DB=default
      - CLICKHOUSE_USER=default
      - CLICKHOUSE_PASSWORD=
      - CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "localhost:8123/ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - infradex-network

  # Rust Collector Service  
  datacollector:
    build:
      context: .
      dockerfile: collector.Dockerfile
    container_name: infradex-collector
    depends_on:
      database:
        condition: service_healthy
    environment:
      - RUST_LOG=info
      - CLICKHOUSE_URL=http://database:8123
      - DATABASE_NAME=default
    volumes:
      - ./logs/collector:/app/logs
      - ./data/collector:/app/data
    restart: unless-stopped
    networks:
      - infradex-network

networks:
  infradex-network:
    driver: bridge

volumes:
  clickhouse_data:
    driver: local
EOF

# Create ClickHouse configuration directory and files
log "Setting up ClickHouse configuration..."
mkdir -p /opt/infradex/clickhouse

# Basic ClickHouse config
cat <<'EOF' > /opt/infradex/clickhouse/config.xml
<?xml version="1.0"?>
<clickhouse>
    <logger>
        <level>information</level>
        <log>/var/log/clickhouse-server/clickhouse-server.log</log>
        <errorlog>/var/log/clickhouse-server/clickhouse-server.err.log</errorlog>
        <size>1000M</size>
        <count>3</count>
    </logger>

    <http_port>8123</http_port>
    <tcp_port>9000</tcp_port>
    <interserver_http_port>9009</interserver_http_port>

    <listen_host>::</listen_host>
    <listen_host>0.0.0.0</listen_host>

    <max_connections>4096</max_connections>
    <keep_alive_timeout>3</keep_alive_timeout>
    <max_concurrent_queries>100</max_concurrent_queries>

    <uncompressed_cache_size>8589934592</uncompressed_cache_size>
    <mark_cache_size>5368709120</mark_cache_size>

    <path>/var/lib/clickhouse/</path>
    <tmp_path>/var/lib/clickhouse/tmp/</tmp_path>
    <user_files_path>/var/lib/clickhouse/user_files/</user_files_path>

    <users_config>users.xml</users_config>
    <default_profile>default</default_profile>
    <default_database>default</default_database>
</clickhouse>
EOF

# Basic ClickHouse users config
cat <<'EOF' > /opt/infradex/clickhouse/users.xml
<?xml version="1.0"?>
<clickhouse>
    <profiles>
        <default>
            <max_memory_usage>10000000000</max_memory_usage>
            <use_uncompressed_cache>0</use_uncompressed_cache>
            <load_balancing>random</load_balancing>
        </default>
    </profiles>

    <users>
        <default>
            <password></password>
            <networks incl="networks" replace="replace">
                <ip>::/0</ip>
            </networks>
            <profile>default</profile>
            <quota>default</quota>
        </default>
    </users>

    <quotas>
        <default>
            <interval>
                <duration>3600</duration>
                <queries>0</queries>
                <errors>0</errors>
                <result_rows>0</result_rows>
                <read_rows>0</read_rows>
                <execution_time>0</execution_time>
            </interval>
        </default>
    </quotas>
</clickhouse>
EOF

# Set proper permissions
chown -R ec2-user:ec2-user /opt/infradex
chmod +x /opt/infradex/docker-compose.yml

log "Setup completed successfully!"

# Create a startup script for the services
cat <<'EOF' > /opt/infradex/start-services.sh
#!/bin/bash
cd /opt/infradex
docker-compose up -d
EOF

chmod +x /opt/infradex/start-services.sh

log "Infradex infrastructure setup completed. Docker Compose is ready to deploy services."
