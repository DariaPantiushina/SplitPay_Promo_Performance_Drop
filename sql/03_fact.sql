-- Normalize funnel steps per session
DROP TABLE IF EXISTS fact.labeled;
CREATE TABLE fact.labeled AS
WITH events_norm AS (
  SELECT
        e.session_id,
        e.ride_id,
        e.user_id,
        e.device_type,
        e.platform,
        e.payment_provider,   -- 'splitpay' | 'card'
        MIN(CASE WHEN e.event_type = 'route_search'    THEN e.event_ts END) AS ts_search,
        MIN(CASE WHEN e.event_type = 'request_ride'    THEN e.event_ts END) AS ts_req,
        MIN(CASE WHEN e.event_type = 'driver_accepted' THEN e.event_ts END) AS ts_acc,
        MIN(CASE WHEN e.event_type = 'ride_started'    THEN e.event_ts END) AS ts_start,
        MIN(CASE WHEN e.event_type = 'ride_completed'  THEN e.event_ts END) AS ts_done,
        MIN(CASE WHEN e.event_type = 'payment_success' THEN e.event_ts END) AS ts_pay
  FROM stg.stg_ride_events e
  WHERE e.event_type IN ('route_search','request_ride','driver_accepted','ride_started','ride_completed','payment_success')
  GROUP BY 1,2,3,4,5,6
)
SELECT
    n.*,
    CASE
        WHEN n.payment_provider='splitpay' THEN 'target'
        ELSE 'control'
    END AS grp,
    CASE
        WHEN n.ts_search BETWEEN DATE '2025-09-15' AND DATE '2025-09-30' THEN 'pre'
        WHEN n.ts_search BETWEEN DATE '2025-10-01' AND DATE '2025-10-15' THEN 'post'
    END AS period
FROM events_norm n;

DROP TABLE IF EXISTS fact.fact_splitpay_status;
CREATE TABLE fact.fact_splitpay_status AS
SELECT
  l.ride_id,
  MAX(l.session_id) AS session_id,
  MAX(CASE WHEN s.event_type='discount_applied' THEN 1 ELSE 0 END) AS has_discount,
  MAX(CASE WHEN s.event_type='discount_error'   THEN 1 ELSE 0 END) AS has_error,
  MAX(CASE WHEN s.event_type='transfer_fail'    THEN 1 ELSE 0 END) AS has_fail
FROM fact.labeled l
LEFT JOIN stg.stg_splitpay_logs s
  ON s.ride_id = l.ride_id
GROUP BY 1;