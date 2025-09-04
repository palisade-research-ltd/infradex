# General Docs

## Bybit

- Account no: in local config, and, in terraform under `bybit_account_01`
- Access Key: Stored in terraform under `bybit_acess_token_01`
- Secret Access Key : Stored in terraform under `bybit_secret_token_01`

## AWS

- main region: `us-east-1`
- access key: Stored in terraform under `AWS_ACCESS_KEY_ID`
- secret key: stored in terraform `AWS_SECRET_ACCESS_KEY`

## Terraform

- organization: `palisade`
- workspace: `dev_infradex`
- projects: `infradex`

## Github

- `infradex`: All the cloud infrastructure definition.
    - Description: AWS Cloud infrastructure for compute, and data layers.
    - Primarily Terraform for AWS, SQL, shell scripts, docker.
    - Hosted microservices: Infrastructure, Data-Platform, Data-Warehouse.

- `interdex`: Inter exchange connectivity.
    - Description: CEX and DEX programmatic integrations.
    - Primarily built with Rust, Shell.
    - Hosted components: Data-Collector.

- `modeldex`: Signal producers, Models.
    - Description: Model definition, training, signal generation.
    - Primarily built with Rust, python.
    - Hosted componets: Feature-Generator, Signal-Cex, Cex-Trader.

- `flaredex`: Solana OnChain programs.
    - Description: OnChain programs for various purposes.
    - Primarily Rust for Solana
    - Hosted components: Signal-Flare, Dex-Trader

