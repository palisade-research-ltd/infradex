-- File: docker/init-trading-schema.sql
-- Database schema for CEX trading data

-- Create database for trading data
CREATE DATABASE IF NOT EXISTS trading_data;

-- Use the trading database
USE trading_data;

-- Order book data table
CREATE TABLE IF NOT EXISTS order_book (
    timestamp DateTime64(3),
    symbol String,
    exchange String,
    side Enum8('buy' = 1, 'sell' = 2),
    price Decimal64(8),
    quantity Decimal64(8),
    order_id String
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (exchange, symbol, timestamp, side)
TTL timestamp + INTERVAL 90 DAY;

-- Trades table
CREATE TABLE IF NOT EXISTS trades (
    timestamp DateTime64(3),
    symbol String,
    exchange String,
    trade_id String,
    price Decimal64(8),
    quantity Decimal64(8),
    side Enum8('buy' = 1, 'sell' = 2),
    buyer_order_id String,
    seller_order_id String
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (exchange, symbol, timestamp)
TTL timestamp + INTERVAL 180 DAY;

-- Market data aggregates (1-minute candles)
CREATE TABLE IF NOT EXISTS market_data_1m (
    timestamp DateTime,
    symbol String,
    exchange String,
    open Decimal64(8),
    high Decimal64(8),
    low Decimal64(8),
    close Decimal64(8),
    volume Decimal64(8),
    trade_count UInt64
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (exchange, symbol, timestamp)
TTL timestamp + INTERVAL 365 DAY;

-- Signals table (from the signals service)
CREATE TABLE IF NOT EXISTS trading_signals (
    timestamp DateTime64(3),
    signal_id String,
    symbol String,
    signal_type Enum8('buy' = 1, 'sell' = 2, 'hold' = 3),
    strength Float64,
    confidence Float64,
    source String,
    metadata String
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (symbol, timestamp, signal_type)
TTL timestamp + INTERVAL 30 DAY;

-- Create materialized view for real-time aggregates
CREATE MATERIALIZED VIEW IF NOT EXISTS trades_1m_mv
TO market_data_1m AS
SELECT
    toStartOfMinute(timestamp) as timestamp,
    symbol,
    exchange,
    argMin(price, timestamp) as open,
    max(price) as high,
    min(price) as low,
    argMax(price, timestamp) as close,
    sum(quantity) as volume,
    count() as trade_count
FROM trades
GROUP BY timestamp, symbol, exchange;
