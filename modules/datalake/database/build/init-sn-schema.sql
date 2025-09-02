
-- Use the trading database
USE operations;

-- Signals table (from the signals service)
CREATE TABLE IF NOT EXISTS trading_signals (
    ts DateTime64(3),
    signal_id String,
    symbol String,
    signal_type Enum8('buy' = 1, 'sell' = 2, 'hold' = 3),
    strength Float64,
    confidence Float64,
    source String,
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(ts)
ORDER BY (symbol, ts, signal_type)
TTL ts + INTERVAL 30 DAY;

