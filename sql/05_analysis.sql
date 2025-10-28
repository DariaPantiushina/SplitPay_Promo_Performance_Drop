-- 1) Difference-in-Differences (SplitPay vs Card)
WITH funnel AS (
  SELECT
        grp, period,
        COUNT(DISTINCT session_id) FILTER (WHERE ts_search IS NOT NULL) AS s_search,
        COUNT(DISTINCT session_id) FILTER (WHERE ts_req IS NOT NULL)    AS s_req,
        COUNT(DISTINCT session_id) FILTER (WHERE ts_done IS NOT NULL)   AS s_done,
        COUNT(DISTINCT session_id) FILTER (WHERE ts_pay IS NOT NULL)    AS s_pay
  FROM fact.labeled
  GROUP BY 1,2
),
rates AS (
  SELECT
        grp, period,
        s_req::float  / NULLIF(s_search,0) AS r_search_to_req,
        s_done::float / NULLIF(s_req,0)    AS r_req_to_done,
        s_pay::float  / NULLIF(s_done,0)   AS r_done_to_pay
  FROM funnel
)
SELECT
      'r_done_to_pay' AS step,
      (MAX(CASE WHEN grp = 'target'  AND period = 'post' THEN r_done_to_pay END)
      - MAX(CASE WHEN grp = 'target'  AND period = 'pre'  THEN r_done_to_pay END))
      - (MAX(CASE WHEN grp = 'control' AND period = 'post' THEN r_done_to_pay END)
      - MAX(CASE WHEN grp = 'control' AND period = 'pre'  THEN r_done_to_pay END)) AS diff_in_diff
FROM rates;

-- 2) Device / Platform breakdown
WITH base AS (
  SELECT *
  FROM fact.labeled
  WHERE period IN ('pre','post')
    AND payment_provider = 'splitpay'
)
SELECT
  device_type, platform, period,
  COUNT(DISTINCT session_id) FILTER (WHERE ts_req IS NOT NULL)::float
    / NULLIF(COUNT(DISTINCT session_id) FILTER (WHERE ts_search IS NOT NULL),0) AS r_search_to_req,
  COUNT(DISTINCT session_id) FILTER (WHERE ts_done IS NOT NULL)::float
    / NULLIF(COUNT(DISTINCT session_id) FILTER (WHERE ts_req IS NOT NULL),0) AS r_req_to_done,
  COUNT(DISTINCT session_id) FILTER (WHERE ts_pay IS NOT NULL)::float
    / NULLIF(COUNT(DISTINCT session_id) FILTER (WHERE ts_done IS NOT NULL),0) AS r_done_to_pay
FROM base
GROUP BY 1,2,3
ORDER BY 1,2,3;

-- 3) Verifying the correct application of discounts (SplitPay logs)
SELECT
      l.device_type,
      l.platform,
      COUNT(DISTINCT l.session_id) FILTER (WHERE s.has_discount = 1 AND l.ts_done IS NOT NULL)::float
               / NULLIF(COUNT(DISTINCT l.session_id) FILTER (WHERE l.ts_done IS NOT NULL),0) AS p_discount_applied,
      COUNT(DISTINCT l.session_id) FILTER (WHERE s.has_error = 1 AND l.ts_done IS NOT NULL)::float
              / NULLIF(COUNT(DISTINCT l.session_id) FILTER (WHERE l.ts_done IS NOT NULL),0) AS p_discount_error,
      COUNT(DISTINCT l.session_id) FILTER (WHERE s.has_fail = 1 AND l.ts_done IS NOT NULL)::float
             / NULLIF(COUNT(DISTINCT l.session_id) FILTER (WHERE l.ts_done IS NOT NULL),0) AS p_transfer_fail
FROM fact.labeled l
LEFT JOIN fact.fact_splitpay_status s ON s.ride_id = l.ride_id
WHERE l.period = 'post' AND l.payment_provider = 'splitpay'
GROUP BY 1,2
ORDER BY 1,2;