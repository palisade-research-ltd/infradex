
-- Use the trading database
USE operations;

--- Liquidations
CREATE TABLE IF NOT EXISTS liquidations (
    ts DateTime64(6, 'UTC'),
    symbol String,
    exchange String,
    side String,
    amount Float64(6),
    price Float64(6),
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(ts)
ORDER BY (symbol, exchange, ts)
SETTINGS index_granularity = 8192

-- MV for real-time aggregates
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_lq_ohlc_1_m
TO lq_ohlc_1_m AS
SELECT
    toStartOfMinute(ts) as ts,
    symbol,
    exchange,
    argMin(amount, ts) as open,
    max(amount) as high,
    min(amount) as low,
    argMax(amount, ts) as close,
    sum(quantity) as volume,
    count(side) as trade_count
FROM trades
GROUP BY ts, symbol, exchange;

