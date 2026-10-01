DROP TABLE IF EXISTS clean_orders;
CREATE TABLE clean_orders AS
SELECT order_id, customer_id, order_status,
       CAST(order_purchase_timestamp AS DATETIME)      AS purchase_ts,
       CAST(order_approved_at AS DATETIME)             AS approved_ts,
       CAST(order_delivered_carrier_date AS DATETIME)  AS carrier_ts,
       CAST(order_delivered_customer_date AS DATETIME) AS delivered_ts,
       CAST(order_estimated_delivery_date AS DATETIME) AS estimated_ts
FROM stg_orders;
ALTER TABLE clean_orders MODIFY order_id VARCHAR(32) NOT NULL, ADD PRIMARY KEY (order_id);

DROP TABLE IF EXISTS clean_customers;
CREATE TABLE clean_customers AS
SELECT customer_id, customer_unique_id,
       customer_zip_code_prefix AS zip_prefix,
       TRIM(customer_city) AS city, customer_state AS state
FROM stg_customers;
ALTER TABLE clean_customers MODIFY customer_id VARCHAR(32) NOT NULL, ADD PRIMARY KEY (customer_id);

DROP TABLE IF EXISTS clean_order_items;
CREATE TABLE clean_order_items AS
SELECT order_id, order_item_id, product_id, seller_id,
       CAST(shipping_limit_date AS DATETIME) AS shipping_limit_ts,
       CAST(price AS DECIMAL(10,2))          AS price,
       CAST(freight_value AS DECIMAL(10,2))  AS freight_value
FROM stg_order_items;

DROP TABLE IF EXISTS clean_payments;
CREATE TABLE clean_payments AS
SELECT order_id, payment_sequential, payment_type, payment_installments,
       CAST(payment_value AS DECIMAL(10,2)) AS payment_value
FROM stg_order_payments;

DROP TABLE IF EXISTS clean_reviews;
CREATE TABLE clean_reviews AS
SELECT order_id, review_id, review_score,
       CAST(review_creation_date AS DATETIME)   AS review_created_ts,
       CAST(review_answer_timestamp AS DATETIME) AS review_answered_ts
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY order_id
                               ORDER BY review_answer_timestamp DESC) AS rn
  FROM stg_order_reviews
) t
WHERE rn = 1;
ALTER TABLE clean_reviews MODIFY order_id VARCHAR(32) NOT NULL, ADD PRIMARY KEY (order_id);

DROP TABLE IF EXISTS clean_products;
CREATE TABLE clean_products AS
SELECT p.product_id,
       COALESCE(p.product_category_name, 'unknown')                       AS category_pt,
       COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       p.product_weight_g AS weight_g, p.product_length_cm AS length_cm,
       p.product_height_cm AS height_cm, p.product_width_cm AS width_cm
FROM stg_products p
LEFT JOIN stg_product_category_name_translation t
       ON p.product_category_name = t.product_category_name;
ALTER TABLE clean_products MODIFY product_id VARCHAR(32) NOT NULL, ADD PRIMARY KEY (product_id);

DROP TABLE IF EXISTS clean_sellers;
CREATE TABLE clean_sellers AS
SELECT seller_id, seller_zip_code_prefix AS zip_prefix,
       TRIM(seller_city) AS city, seller_state AS state
FROM stg_sellers;
ALTER TABLE clean_sellers MODIFY seller_id VARCHAR(32) NOT NULL, ADD PRIMARY KEY (seller_id);

DROP TABLE IF EXISTS clean_geolocation;
CREATE TABLE clean_geolocation AS
SELECT geolocation_zip_code_prefix AS zip_prefix,
       AVG(geolocation_lat) AS lat, AVG(geolocation_lng) AS lng
FROM stg_geolocation
GROUP BY geolocation_zip_code_prefix;
