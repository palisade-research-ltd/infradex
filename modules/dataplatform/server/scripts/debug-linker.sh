#!/bin/bash
set -e

echo "🔍 Debugging ARM64 linker issue..."

# Check current architecture
echo "Current architecture: $(uname -m)"

# Check Rust configuration
echo "Default Rust target:"
rustc --print cfg | grep target

echo "Installed targets:"
rustup target list --installed

echo "Environment variables (cross-compilation related):"
env | grep -i aarch64 || echo "No aarch64 env vars found"
env | grep -i cross || echo "No cross env vars found"
env | grep -i target || echo "No target env vars found"

# Check for cargo configuration
echo "Checking for .cargo/config.toml:"
if [ -f ~/.cargo/config.toml ]; then
    echo "Found ~/.cargo/config.toml:"
    cat ~/.cargo/config.toml
else
    echo "No ~/.cargo/config.toml found"
fi

if [ -f .cargo/config.toml ]; then
    echo "Found .cargo/config.toml:"
    cat .cargo/config.toml
else
    echo "No .cargo/config.toml found"
fi

# Check available linkers
echo "Available GCC variants:"
which gcc || echo "gcc not found"
which aarch64-linux-gnu-gcc || echo "aarch64-linux-gnu-gcc not found (this is good for native builds)"

echo "✅ Debug complete. For native builds on ARM64, you should NOT see aarch64-linux-gnu-gcc"
