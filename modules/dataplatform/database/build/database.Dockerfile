# Base image
FROM clickhouse/clickhouse-server:latest

RUN echo "remove previous data"
# Remove default password file that may override configuration
RUN rm -f /etc/clickhouse-server/users.d/default-password.xml

# Create required directories with proper permissions
RUN echo "create /var/lib/clickhouse folders"
RUN mkdir -p /var/lib/clickhouse/format_schemas && \
    mkdir -p /var/lib/clickhouse/access && \
    mkdir -p /var/lib/clickhouse/user_files && \
    mkdir -p /var/lib/clickhouse/tmp && \
    mkdir -p /var/log/clickhouse-server && \
    mkdir -p /var/lib/clickhouse/data && \
    mkdir -p /var/lib/clickhouse/metadata && \
    mkdir -p /docker-entrypoint-initdb.d

RUN echo "change ownerships and permissions for clickhouse /var/lib and /var/log"
RUN chown -R clickhouse:clickhouse /var/lib/clickhouse && \
    chown -R clickhouse:clickhouse /var/log/clickhouse-server

# Copy configuration files
COPY database/configs/config.xml /etc/clickhouse-server/config.d/config.xml
COPY database/configs/users.xml /etc/clickhouse-server/users.d/users.xml

# Copy initialization SQL scripts to the init directory (FIXED LOCATION)
RUN echo "Copy initialization queries.."
COPY database/build/init-lq-schema.sql /docker-entrypoint-initdb.d/init-lq-schema.sql
COPY database/build/init-ob-schema.sql /docker-entrypoint-initdb.d/init-ob-schema.sql
COPY database/build/init-pt-schema.sql /docker-entrypoint-initdb.d/init-pt-schema.sql
COPY database/build/init-sn-schema.sql /docker-entrypoint-initdb.d/init-sn-schema.sql

# Set proper permissions for all files
RUN chown -R clickhouse:clickhouse /etc/clickhouse-server/ && \
    chown -R clickhouse:clickhouse /docker-entrypoint-initdb.d/ && \
    chmod 644 /etc/clickhouse-server/config.d/config.xml && \
    chmod 644 /etc/clickhouse-server/users.d/users.xml && \
    chmod 644 /docker-entrypoint-initdb.d/*.sql

# Copy and set up custom entrypoint script
COPY database/scripts/database_entrypoint.sh /database-entrypoint.sh
RUN chmod +x /database-entrypoint.sh && \
    chown clickhouse:clickhouse /database-entrypoint.sh

# Expose standard ClickHouse ports
EXPOSE 8123 9000 9009

# Use custom entrypoint
ENTRYPOINT ["/database-entrypoint.sh"]

