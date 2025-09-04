# Deployment of compiled Rust Data collector binary
FROM debian:bookworm-slim

# Set working directory
WORKDIR /app

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

# Copy the binary from build directory (relative to build context)
# The build context is /opt/infradex/collector/ so files are in build/
COPY build/collector_arm64 /usr/local/bin/collector
RUN chmod +x /usr/local/bin/collector && \
    chown root:root /usr/local/bin/collector

# Copy configuration files from configs directory
COPY configs/collector_config.toml /app/config/
RUN chown appuser:appuser /app/config/collector_config.toml

# Switch to non-root user
USER appuser
WORKDIR /app

# Environment variables
ENV RUST_LOG=info
ENV CONFIG_PATH=/app/config/collector_config.toml
ENV CLICKHOUSE_URL=http://localhost:8123

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep collector > /dev/null || exit 1

# Run the collector
CMD ["/usr/local/bin/collector"]
