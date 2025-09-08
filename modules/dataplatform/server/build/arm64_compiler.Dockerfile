# ARM64 Rust Compiler Dockerfile for AWS EC2 t4g.small
# This Dockerfile builds a Rust collector binary with git dependencies for ARM64 architecture

# Use multi-stage build for optimization
FROM --platform=linux/arm64 lukemathwalker/cargo-chef:latest-rust-1.75 AS chef
WORKDIR /app
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

# Install required build dependencies for ARM64
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    build-essential \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Configure Git to use HTTPS instead of SSH for dependencies
RUN git config --global url."https://github.com/".insteadOf "git@github.com:" \
    && git config --global url."https://".insteadOf "git://"

# Stage 1: Plan dependencies
FROM chef AS planner
COPY . .
# Create recipe file for cargo-chef
RUN cargo chef prepare --recipe-path recipe.json

# Stage 2: Build dependencies
FROM chef AS builder

# Copy the recipe file
COPY --from=planner /app/recipe.json recipe.json

# Build dependencies (this layer will be cached)
RUN cargo chef cook --release --recipe-path recipe.json

# Copy source code
COPY . .

# Create a proper Cargo.toml for the collector binary
RUN mkdir -p src/bin

# Create the collector binary Cargo.toml entry if not exists
# This ensures the collector.rs can be built as a binary
COPY <<EOF Cargo.toml
[package]
name = "collector"
version = "0.1.0"
edition = "2021"

[[bin]]
name = "collector"
path = "src/bin/collector.rs"

[dependencies]
tokio = { version = "1.0", features = ["full"] }
anyhow = "1.0"

# Git dependencies - using HTTPS instead of SSH
atelier_data = { git = "https://github.com/IteraLabs/atelier-rs.git" }
ix_execution = { git = "https://github.com/your-org/ix-execution.git", optional = true }
ix_cex = { git = "https://github.com/your-org/ix-cex.git", optional = true }

# If the above git repos don't exist or are private, you can replace with:
# atelier_data = { path = "./atelier-data" }  # if you have local copy
# ix_execution = { path = "./ix-execution" }  # if you have local copy  
# ix_cex = { path = "./ix-cex" }  # if you have local copy

[features]
default = ["ix_execution", "ix_cex"]
ix_execution = ["dep:ix_execution"]
ix_cex = ["dep:ix_cex"]
EOF

# Build the collector binary for ARM64
RUN cargo build --release --bin collector

# Stage 3: Extract the binary to output directory
FROM --platform=linux/arm64 debian:bookworm-slim AS extractor
WORKDIR /output

# Copy the compiled binary
COPY --from=builder /app/target/release/collector ./collector

# Make it executable
RUN chmod +x ./collector

# Create a simple script to copy the binary to the host
RUN echo '#!/bin/bash' > extract.sh \
    && echo 'cp /output/collector /host/collector' >> extract.sh \
    && chmod +x extract.sh

# Default command to extract binary
CMD ["./extract.sh"]

# Alternative: Create a final runtime stage (optional)
FROM --platform=linux/arm64 debian:bookworm-slim AS runtime
WORKDIR /app

# Install runtime dependencies if needed
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the binary
COPY --from=builder /app/target/release/collector .

# Make it executable
RUN chmod +x collector

# Expose any ports your collector might use (adjust as needed)
EXPOSE 8080

# Run the collector
CMD ["./collector"]
