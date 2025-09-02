
-- Use the trading database
USE operations;

-- Trades
CREATE TABLE IF NOT EXISTS publictrades (
    ts DateTime64(6, 'UTC'),
    symbol String,
    side String,
    amount Float64(6), 
    price Float64(6),
    exchange String,
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(ts)
ORDER BY (symbol, ts, exchange)
SETTINGS index_granularity = 8192

-- MV for real-time aggregates
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_pt_ohlc_1_m
TO pt_ohlc_1_m AS
SELECT
    toStartOfMinute(ts) as ts,
    symbol,
    exchange,
    argMin(price, ts) as open,
    max(price) as high,
    min(price) as low,
    argMax(price, ts) as close,
    sum(amount) as volume,
    count() as trade_count
FROM trades
GROUP BY ts, symbol, exchange;

