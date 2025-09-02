# File: datalake/database/build/database.Dockerfile
# Enhanced Clickhouse database setup for CEX Trading Data

# Base image
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
    mkdir -p /docker-entrypoint-initdb.d && \
    chown -R clickhouse:clickhouse /var/lib/clickhouse && \
    chown -R clickhouse:clickhouse /var/log/clickhouse-server

# Copy configuration files
COPY opt/infradex/database/configs/config.xml /etc/clickhouse-server/config.d/config.xml
COPY opt/infradex/database/configs/users.xml /etc/clickhouse-server/users.d/users.xml

# Copy initialization SQL scripts to the init directory (FIXED LOCATION)
COPY opt/infradex/database/build/init-lq-schema.sql /docker-entrypoint-initdb.d/01-init-lq-schema.sql
COPY opt/infradex/database/build/init-ob-schema.sql /docker-entrypoint-initdb.d/02-init-ob-schema.sql
COPY opt/infradex/database/build/init-pt-schema.sql /docker-entrypoint-initdb.d/03-init-pt-schema.sql
COPY opt/infradex/database/build/init-sn-schema.sql /docker-entrypoint-initdb.d/04-init-sn-schema.sql

# Set proper permissions for all files
RUN chown -R clickhouse:clickhouse /etc/clickhouse-server/ && \
    chown -R clickhouse:clickhouse /docker-entrypoint-initdb.d/ && \
    chmod 644 /etc/clickhouse-server/config.d/config.xml && \
    chmod 644 /etc/clickhouse-server/users.d/users.xml && \
    chmod 644 /docker-entrypoint-initdb.d/*.sql

# Copy and set up custom entrypoint script
COPY opt/infradex/database/scripts/entrypoint.sh /custom-entrypoint.sh
RUN chmod +x /custom-entrypoint.sh && \
    chown clickhouse:clickhouse /custom-entrypoint.sh

# Health check with better validation
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD wget --spider -q http://localhost:8123/ping && \
        clickhouse-client --query "SELECT 1" || exit 1

# Expose standard ClickHouse ports
EXPOSE 8123 9000 9009

# Use custom entrypoint
ENTRYPOINT ["/custom-entrypoint.sh"]
