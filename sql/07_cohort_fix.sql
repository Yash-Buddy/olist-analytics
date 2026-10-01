ALTER TABLE clean_customers
  MODIFY customer_unique_id VARCHAR(32) NOT NULL,
  ADD INDEX idx_unique (customer_unique_id);

DROP TABLE IF EXISTS cohort_base;
CREATE TABLE cohort_base AS
SELECT DISTINCT c.customer_unique_id,
       CAST(DATE_FORMAT(o.purchase_ts, '%Y-%m-01') AS DATE) AS m
FROM clean_orders o
JOIN clean_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';
ALTER TABLE cohort_base ADD INDEX idx_cb (customer_unique_id, m);

DROP TABLE IF EXISTS cohort_first;
CREATE TABLE cohort_first AS
SELECT customer_unique_id, MIN(m) AS cohort
FROM cohort_base GROUP BY customer_unique_id;
ALTER TABLE cohort_first ADD INDEX idx_cf (customer_unique_id);

CREATE OR REPLACE VIEW vw_cohort AS
SELECT f.cohort,
       TIMESTAMPDIFF(MONTH, f.cohort, b.m) AS month_index,
       COUNT(*) AS customers
FROM cohort_base b
JOIN cohort_first f ON b.customer_unique_id = f.customer_unique_id
GROUP BY f.cohort, month_index;
