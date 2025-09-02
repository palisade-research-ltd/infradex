# File: docker/collector.Dockerfile  
# Multi-stage build for Rust collector binary

# Build stage
FROM rust:1.75-slim # as builder
WORKDIR /app

# Install system dependencies for building
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# WORKDIR /app/collector
# Build dependencies (this layer will be cached)
# RUN cargo build --release && rm src/*.rs target/release/deps/collector*

# Copy source code from interdex project
# Note: You'll need to clone or copy the interdex source here
# COPY src/ ./src/

# Build the actual collector binary
# RUN cargo build --release

# Runtime stage
# FROM debian:bullseye-slim

# Install runtime dependencies
# RUN apt-get update && apt-get install -y \
#    ca-certificates \
#    wget \
#    curl \
#    && rm -rf /var/lib/apt/lists/*

# Create app user for security
RUN useradd -r -u 1001 appuser

# Create necessary directories
RUN mkdir -p /app/logs /app/data /app/config && \
    chown -R appuser:appuser /app

# Copy the binary from local environment
COPY collector_arm64 /usr/local/bin/collector_arm64
RUN chmod +x /usr/local/bin/collector_arm64

# Copy configuration files
COPY collector_config.toml /app/config/

# Switch to non-root user
USER appuser
WORKDIR /app

# Environment variables
ENV RUST_LOG=info
ENV CONFIG_PATH=/app/config/collector_config.toml

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep collector_arm64 > /dev/null || exit 1

# Run the collector
CMD ["collector_arm64"]
