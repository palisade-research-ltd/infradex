
-- Database for trading operations data
CREATE DATABASE IF NOT EXISTS operations;

-- Use the trading database
USE operations;

--- Orderbooks
CREATE TABLE IF NOT EXISTS orderbooks (
    ts DateTime64(6, 'UTC'),
    symbol String,
    exchange String,
    bids Array(Tuple(Float64, Float64)),
    asks Array(Tuple(Float64, Float64)),
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(ts)
ORDER BY (symbol, exchange, ts)
SETTINGS index_granularity = 8192

-- Target table for minute-spaced orderbook snapshots
CREATE TABLE IF NOT EXISTS ob_1_min (
    -- Rounded minute (00:00:00, 00:01:00, etc.)
    ts_m DateTime('UTC'),
    -- Original timestamp of the selected snapshot
    ts DateTime64(6, 'UTC'),   
    symbol String,
    exchange String,
    bids Array(Tuple(Float64, Float64)),
    asks Array(Tuple(Float64, Float64))
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(ts_m)
ORDER BY (symbol, exchange, ts_m)
SETTINGS index_granularity = 8192;

-- MV to get last snapshot per minute
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_ob_1_min 
TO ob_1_min
AS
SELECT 
    toStartOfMinute(ts) AS ts_min,
    argMax(ts, ts) AS ts,
    symbol,
    exchange,
    argMax(bids, ts) AS bids,
    argMax(asks, ts) AS asks
FROM orderbooks
GROUP BY 
    toStartOfMinute(ts),
    symbol, 
    exchange;

