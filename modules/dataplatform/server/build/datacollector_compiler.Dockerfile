# Stage 1: build environment
from rust:1.85 as builder
WORKDIR /app

RUN chown -R root:root /app
RUN chmod 755 /app

# install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    gcc \
    ca-certificates \
    pkg-config \
    libssl-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

ENV CC=gcc
ENV CXX=g++

# configure git for https
RUN git config --global url."https://github.com/".insteadof "git@github.com:"

# clone the repository
RUN git clone https://github.com/palisade-research-ltd/interdex.git .

# navigate to the ix-execution directory
WORKDIR /app/ix-execution

# Remove any existing cargo configuration that might force cross-compilation
RUN rm -rf ~/.cargo/ .cargo/ target/

# Verify the collector.rs exists
RUN ls -la src/bin/collector.rs || (echo "collector.rs not found!")

# Build the collector binary in release mode
RUN cargo build --bin collector
RUN echo "collector binary successfully built"

# List contents to verify build
RUN ls -la target/release/

# Verify the binary was created and is executable
RUN test -f target/release/collector && echo "Binary created successfully" || (echo "Binary not found!")

# Create directory and copy binary correctly
RUN echo "Create dir and copy binary"
RUN mkdir -p datacollector/build
RUN cp target/release/collector datacollector/build/datacollector_arm_64  
RUN cp target/release/collector /usr/local/bin/datacollector
RUN chmod +x /usr/local/bin/datacollector

CMD ["/bin/bash"]
