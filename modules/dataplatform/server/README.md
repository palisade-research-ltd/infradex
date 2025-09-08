# Server

pre-configuration and tool building.

## Compiling binaries with docker

Check the architecture, and, what the rust compiler sees as default target

```shell
uname -m && docker run --rm rust:1.85 rustc --print cfg | grep target
```

Check if there are any cross-compilation targets installed

```shell
docker run --rm rust:1.85 rustup target list --installed
```

A Test for minimal Rust build
```shell
docker run --rm -v $(pwd):/workspace -w /workspace rust:1.85 sh -c "
cargo init test-build --bin --name container_test
cd test-build  
cargo build --release
file target/release/container_test
"
```

