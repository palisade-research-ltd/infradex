# Deployment of compiled Rust Data collector binary
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create app user for security
RUN useradd -r -u 1001 appuser

# Create necessary directories with proper permissions
RUN mkdir -p /app/logs /app/data /app/config && \
    chown -R appuser:appuser /app

# Copy files - using the exact paths that should exist in build context
# When building from /opt/infradex, these paths should be relative to that
COPY datacollector/build/datacollector_arm_64 /usr/local/bin/datacollector
COPY datacollector/configs/datacollector_config.toml /app/config/

# Set permissions
RUN chmod +x /usr/local/bin/datacollector && \
    chown root:root /usr/local/bin/datacollector && \
    chown appuser:appuser /app/config/datacollector_config.toml

# Switch to non-root user and set working directory
USER appuser
WORKDIR /app

# Environment variables
ENV RUST_LOG=info \
    CONFIG_PATH=/app/config/datacollector_config.toml \
    CLICKHOUSE_URL=http://database-clickhouse:8123

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep datacollector > /dev/null || exit 1

# Run the collector
CMD ["/usr/local/bin/datacollector"]
