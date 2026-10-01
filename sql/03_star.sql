-- Dimensions
SET SESSION cte_max_recursion_depth = 2000;
DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date AS
WITH RECURSIVE d AS (
  SELECT DATE('2016-01-01') AS dt
  UNION ALL
  SELECT dt + INTERVAL 1 DAY FROM d WHERE dt < '2018-12-31'
)
SELECT CAST(DATE_FORMAT(dt, '%Y%m%d') AS UNSIGNED) AS date_key,
       dt AS full_date, YEAR(dt) AS year, QUARTER(dt) AS quarter,
       MONTH(dt) AS month, MONTHNAME(dt) AS month_name,
       DAYNAME(dt) AS day_name, DAYOFWEEK(dt) IN (1,7) AS is_weekend
FROM d;
ALTER TABLE dim_date ADD PRIMARY KEY (date_key);

DROP TABLE IF EXISTS dim_customer;
CREATE TABLE dim_customer AS SELECT * FROM clean_customers;
ALTER TABLE dim_customer ADD PRIMARY KEY (customer_id);

DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product AS SELECT * FROM clean_products;
ALTER TABLE dim_product ADD PRIMARY KEY (product_id);

DROP TABLE IF EXISTS dim_seller;
CREATE TABLE dim_seller AS SELECT * FROM clean_sellers;
ALTER TABLE dim_seller ADD PRIMARY KEY (seller_id);

-- Fact 1: one row per order item
DROP TABLE IF EXISTS fact_order_items;
CREATE TABLE fact_order_items AS
SELECT i.order_id, i.order_item_id, i.product_id, i.seller_id, o.customer_id,
       CAST(DATE_FORMAT(o.purchase_ts, '%Y%m%d') AS UNSIGNED) AS date_key,
       i.price, i.freight_value
FROM clean_order_items i
JOIN clean_orders o ON i.order_id = o.order_id;
ALTER TABLE fact_order_items
  MODIFY order_id VARCHAR(32) NOT NULL,
  ADD PRIMARY KEY (order_id, order_item_id),
  ADD INDEX idx_product (product_id),
  ADD INDEX idx_seller (seller_id),
  ADD INDEX idx_customer (customer_id),
  ADD INDEX idx_date (date_key);

-- Fact 2: one row per order (payments summed first, so no double counting)
DROP TABLE IF EXISTS fact_orders;
CREATE TABLE fact_orders AS
SELECT o.order_id, o.customer_id, o.order_status,
       CAST(DATE_FORMAT(o.purchase_ts, '%Y%m%d') AS UNSIGNED) AS date_key,
       i.item_count, i.items_value, i.freight_total,
       p.payment_total, r.review_score,
       DATEDIFF(o.delivered_ts, o.purchase_ts)  AS delivery_days,
       DATEDIFF(o.delivered_ts, o.estimated_ts) AS delay_days
FROM clean_orders o
LEFT JOIN (SELECT order_id, COUNT(*) AS item_count,
                  SUM(price) AS items_value, SUM(freight_value) AS freight_total
           FROM clean_order_items GROUP BY order_id) i ON o.order_id = i.order_id
LEFT JOIN (SELECT order_id, SUM(payment_value) AS payment_total
           FROM clean_payments GROUP BY order_id) p ON o.order_id = p.order_id
LEFT JOIN clean_reviews r ON o.order_id = r.order_id;
ALTER TABLE fact_orders
  MODIFY order_id VARCHAR(32) NOT NULL,
  ADD PRIMARY KEY (order_id),
  ADD INDEX idx_customer (customer_id),
  ADD INDEX idx_date (date_key);
