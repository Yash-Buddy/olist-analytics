-- 1. Monthly revenue with month-over-month growth (LAG)
CREATE OR REPLACE VIEW vw_monthly_revenue AS
WITH m AS (
  SELECT d.year, d.month, SUM(f.price) AS revenue, COUNT(DISTINCT f.order_id) AS orders
  FROM fact_order_items f JOIN dim_date d ON f.date_key = d.date_key
  GROUP BY d.year, d.month
)
SELECT year, month, revenue, orders,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY year, month))
             * 100 / LAG(revenue) OVER (ORDER BY year, month), 1) AS mom_growth_pct
FROM m;

-- 2. Top 3 categories per year (RANK + PARTITION BY)
CREATE OR REPLACE VIEW vw_top_categories_by_year AS
SELECT * FROM (
  SELECT d.year, p.category, SUM(f.price) AS revenue,
         RANK() OVER (PARTITION BY d.year ORDER BY SUM(f.price) DESC) AS rnk
  FROM fact_order_items f
  JOIN dim_product p ON f.product_id = p.product_id
  JOIN dim_date d ON f.date_key = d.date_key
  GROUP BY d.year, p.category
) t WHERE rnk <= 3;

-- 3. RFM
CREATE OR REPLACE VIEW vw_rfm_base AS
SELECT c.customer_unique_id,
       DATEDIFF((SELECT MAX(purchase_ts) FROM clean_orders), MAX(o.purchase_ts)) AS recency,
       COUNT(DISTINCT o.order_id) AS frequency,
       SUM(f.items_value) AS monetary
FROM clean_orders o
JOIN clean_customers c ON o.customer_id = c.customer_id
JOIN fact_orders f ON o.order_id = f.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id;

CREATE OR REPLACE VIEW vw_rfm_scored AS
SELECT *,
       6 - NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
       CASE WHEN frequency = 1 THEN 1 WHEN frequency = 2 THEN 3 ELSE 5 END AS f_score,
       NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
FROM vw_rfm_base;

CREATE OR REPLACE VIEW vw_rfm_segments AS
SELECT *,
       CASE
         WHEN r_score >= 4 AND f_score = 5 THEN 'Champions'
         WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
         WHEN r_score >= 4 AND f_score = 1 THEN 'New'
         WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
         WHEN r_score = 1  AND f_score = 1 THEN 'Lost'
         ELSE 'Need Attention'
       END AS segment
FROM vw_rfm_scored;

-- 4. Cohort retention
CREATE OR REPLACE VIEW vw_cohort AS
WITH co AS (
  SELECT c.customer_unique_id,
         CAST(DATE_FORMAT(o.purchase_ts, '%Y-%m-01') AS DATE) AS m
  FROM clean_orders o JOIN clean_customers c ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
),
first AS (
  SELECT customer_unique_id, MIN(m) AS cohort FROM co GROUP BY customer_unique_id
)
SELECT f.cohort, TIMESTAMPDIFF(MONTH, f.cohort, co.m) AS month_index,
       COUNT(DISTINCT co.customer_unique_id) AS customers
FROM co JOIN first f ON co.customer_unique_id = f.customer_unique_id
GROUP BY f.cohort, month_index;

-- 5. ABC analysis (running total with a window frame)
CREATE OR REPLACE VIEW vw_abc AS
WITH r AS (
  SELECT p.category, SUM(f.price) AS revenue, COUNT(*) AS items_sold
  FROM fact_order_items f JOIN dim_product p ON f.product_id = p.product_id
  GROUP BY p.category
),
c AS (
  SELECT *, SUM(revenue) OVER () AS total,
         SUM(revenue) OVER (ORDER BY revenue DESC
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running
  FROM r
)
SELECT category, revenue, items_sold,
       ROUND(running * 100 / total, 1) AS cumulative_pct,
       CASE WHEN running * 100 / total <= 80 THEN 'A'
            WHEN running * 100 / total <= 95 THEN 'B' ELSE 'C' END AS abc_class
FROM c;

-- 6. Seller delivery performance (NTILE quartiles)
CREATE OR REPLACE VIEW vw_seller_delivery AS
WITH s AS (
  SELECT i.seller_id, COUNT(DISTINCT i.order_id) AS orders,
         ROUND(AVG(o.delay_days), 1) AS avg_delay_days
  FROM fact_order_items i JOIN fact_orders o ON i.order_id = o.order_id
  WHERE o.order_status = 'delivered' AND o.delay_days IS NOT NULL
  GROUP BY i.seller_id HAVING COUNT(DISTINCT i.order_id) >= 30
)
SELECT *, NTILE(4) OVER (ORDER BY avg_delay_days) AS delay_quartile FROM s;
