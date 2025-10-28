DROP TABLE IF EXISTS marts.ride_funnel_metrics;
CREATE TABLE marts.ride_funnel_metrics AS
WITH joined AS (
  SELECT
        f.device_type,
        f.platform,
        f.payment_provider,
        f.period,
        DATE_TRUNC('day', f.ts_done) AS event_date,  -- 🔸 добавляем временную ось
        f.session_id,
        f.ride_id,
        f.ts_search, f.ts_req, f.ts_done, f.ts_pay,
        COALESCE(s.has_discount,0) AS has_discount,
        COALESCE(s.has_error,0)   AS has_error,
        COALESCE(s.has_fail,0)    AS has_fail
  FROM fact.labeled f
  LEFT JOIN fact.fact_splitpay_status s ON s.ride_id = f.ride_id
  WHERE f.ts_search BETWEEN '2025-09-15' AND '2025-10-15'
)
SELECT
      event_date, 
      device_type, platform, payment_provider, period,
      COUNT(DISTINCT ride_id) FILTER (WHERE ts_search IS NOT NULL) AS cnt_search,
      COUNT(DISTINCT ride_id) FILTER (WHERE ts_req    IS NOT NULL) AS cnt_req,
      COUNT(DISTINCT ride_id) FILTER (WHERE ts_done   IS NOT NULL) AS cnt_done,
      COUNT(DISTINCT ride_id) FILTER (WHERE ts_pay    IS NOT NULL) AS cnt_pay,
      COUNT(DISTINCT ride_id) FILTER (WHERE has_discount = 1 AND ts_done IS NOT NULL) AS cnt_discount,
      COUNT(DISTINCT ride_id) FILTER (WHERE has_error = 1    AND ts_done IS NOT NULL) AS cnt_error,
      COUNT(DISTINCT ride_id) FILTER (WHERE has_fail = 1     AND ts_done IS NOT NULL) AS cnt_fail,
      COUNT(DISTINCT ride_id) FILTER (WHERE ts_req  IS NOT NULL)::FLOAT / NULLIF(COUNT(DISTINCT ride_id) FILTER (WHERE ts_search IS NOT NULL),0) AS r_search_to_req,
      COUNT(DISTINCT ride_id) FILTER (WHERE ts_done IS NOT NULL)::FLOAT / NULLIF(COUNT(DISTINCT ride_id) FILTER (WHERE ts_req    IS NOT NULL),0) AS r_req_to_done,
      COUNT(DISTINCT ride_id) FILTER (WHERE ts_pay  IS NOT NULL)::FLOAT / NULLIF(COUNT(DISTINCT ride_id) FILTER (WHERE ts_done   IS NOT NULL),0) AS r_done_to_pay,
      COUNT(DISTINCT ride_id) FILTER (WHERE has_discount = 1 AND ts_done IS NOT NULL)::FLOAT / NULLIF(COUNT(DISTINCT ride_id) FILTER (WHERE ts_done IS NOT NULL),0) AS p_discount_applied,
      COUNT(DISTINCT ride_id) FILTER (WHERE has_error = 1    AND ts_done IS NOT NULL)::FLOAT / NULLIF(COUNT(DISTINCT ride_id) FILTER (WHERE ts_done IS NOT NULL),0) AS p_discount_error,
      COUNT(DISTINCT ride_id) FILTER (WHERE has_fail = 1     AND ts_done IS NOT NULL)::FLOAT / NULLIF(COUNT(DISTINCT ride_id) FILTER (WHERE ts_done IS NOT NULL),0) AS p_transfer_fail
FROM joined
GROUP BY 1,2,3,4,5
ORDER BY 1,2,3,4,5;