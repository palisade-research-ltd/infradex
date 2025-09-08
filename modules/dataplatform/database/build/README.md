# Initial Build for Database

## Build

- previous (server): 
- `build/database.Dockerfile`: 
    - Copy files: config.xml, users.xml, init-xx-schema.sql
- `scripts/database_entrypoint.sh`:

## Schemas

- Orderbooks (orderbooks - ob)
- Public Trades (publictrades - pt)
- Liquidations (liquidations - lq)
- Signals (signals - sn)

## Materialized Views

- Orderbook Snapshots (mv_ob_x_t)
- PublicTrades OHLC (mv_pt_ohlc_x_t)

