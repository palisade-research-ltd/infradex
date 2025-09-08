# compile.Dockerfile - Direct libtorch download version
FROM --platform=linux/arm64 rust:1.75

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    libssl-dev \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install libtorch for ARM64
RUN cd /tmp && \
    wget https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-latest.zip && \
    unzip libtorch-shared-with-deps-latest.zip && \
    mv libtorch /opt/ && \
    rm libtorch-shared-with-deps-latest.zip

# Set up environment variables for torch-sys
ENV LIBTORCH=/opt/libtorch
ENV LIBTORCH_USE_PYTORCH=0
ENV TORCH_CUDA_VERSION=none
ENV LD_LIBRARY_PATH=/opt/libtorch/lib:$LD_LIBRARY_PATH
ENV LIBTORCH_LIB_DIR=/opt/libtorch/lib
ENV LIBTORCH_INCLUDE_DIR=/opt/libtorch/include

# Create pkg-config file
RUN mkdir -p /usr/local/lib/pkgconfig && \
    cat > /usr/local/lib/pkgconfig/torch.pc << 'EOF'
      prefix=/opt/libtorch
      exec_prefix=${prefix}
      libdir=${prefix}/lib
      includedir=${prefix}/include

      Name: torch
      Description: PyTorch C++ Library
      Version: 2.1.0
      Libs: -L${libdir} -ltorch -ltorch_cpu -ltorch_global_deps
      Cflags: -I${includedir} -I${includedir}/torch/csrc/api/include
    EOF

# Update pkg-config path
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# Verify installation
RUN echo "LibTorch files:" && \
    ls -la /opt/libtorch/lib/ | grep -E "\\.so" | head -5 && \
    echo "Checking library architecture:" && \
    file /opt/libtorch/lib/libtorch.so

WORKDIR /workspace

# Default command
CMD ["echo", "LibTorch ARM64 compilation environment ready"]
