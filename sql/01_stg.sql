DROP TABLE IF EXISTS stg.stg_ride_events;
CREATE TABLE stg.stg_ride_events (
  session_id TEXT,
  ride_id TEXT,
  user_id TEXT,
  city_id TEXT,
  device_type TEXT,
  platform TEXT,
  payment_provider TEXT,
  event_type TEXT,
  event_ts TIMESTAMP
);

DROP TABLE IF EXISTS stg.stg_splitpay_logs;
CREATE TABLE stg.stg_splitpay_logs (
  ride_id TEXT,
  session_id TEXT,
  event_type TEXT,
  event_ts TIMESTAMP
);

DROP TABLE IF EXISTS stg.stg_driver_supply;
CREATE TABLE stg.stg_driver_supply (
  city_id TEXT,
  snapshot_ts TIMESTAMP,
  active_drivers INT,
  avg_eta FLOAT
);