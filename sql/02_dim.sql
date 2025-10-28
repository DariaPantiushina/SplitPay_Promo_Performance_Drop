DROP TABLE IF EXISTS dim.dim_device;
CREATE TABLE dim.dim_device AS
SELECT DISTINCT device_type, platform
FROM stg.stg_ride_events;

DROP TABLE IF EXISTS dim.dim_payment_provider;
CREATE TABLE dim.dim_payment_provider AS
SELECT DISTINCT payment_provider 
FROM stg.stg_ride_events;

DROP TABLE IF EXISTS dim.dim_period;
CREATE TABLE dim.dim_period AS
SELECT
    DATE '2025-09-15' AS pre_from,
    DATE '2025-09-30' AS pre_to,
    DATE '2025-10-01' AS post_from,
    DATE '2025-10-15' AS post_to;