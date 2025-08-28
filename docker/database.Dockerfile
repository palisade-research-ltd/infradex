# File: docker/database.Dockerfile
# Enhanced ClickHouse database setup for CEX trading data

FROM clickhouse/clickhouse-server:latest

# Remove default password file that may override configuration
RUN rm -f /etc/clickhouse-server/users.d/default-password.xml

# Create required directories with proper permissions
RUN mkdir -p /var/lib/clickhouse/format_schemas && \
    mkdir -p /var/lib/clickhouse/access && \
    mkdir -p /var/lib/clickhouse/user_files && \
    mkdir -p /var/lib/clickhouse/tmp && \
    mkdir -p /var/log/clickhouse-server && \
    mkdir -p /var/lib/clickhouse/data && \
    mkdir -p /var/lib/clickhouse/metadata && \
    chown -R clickhouse:clickhouse /var/lib/clickhouse && \
    chown -R clickhouse:clickhouse /var/log/clickhouse-server

# Copy configuration files
COPY clickhouse/config.xml /etc/clickhouse-server/config.xml
COPY clickhouse/users.xml /etc/clickhouse-server/users.xml

# Set proper permissions for configuration files
RUN chown -R clickhouse:clickhouse /etc/clickhouse-server/ && \
    chmod 644 /etc/clickhouse-server/config.xml && \
    chmod 644 /etc/clickhouse-server/users.xml

# Create initial database schema for trading data
COPY docker/init-trading-schema.sql /docker-entrypoint-initdb.d/

# Health check with better validation
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD wget --spider -q http://localhost:8123/ping && \
        clickhouse-client --query "SELECT 1" || exit 1

# Expose standard ClickHouse ports
EXPOSE 8123 9000 9009

# Enhanced entrypoint script
COPY scripts/entrypoint.sh /custom-entrypoint.sh
RUN chmod +x /custom-entrypoint.sh

ENTRYPOINT ["/custom-entrypoint.sh"]
