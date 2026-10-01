SELECT 'fact_order_items' AS tbl, COUNT(*) AS n, ROUND(SUM(price),2) AS total_price FROM fact_order_items
UNION ALL
SELECT 'clean_order_items', COUNT(*), ROUND(SUM(price),2) FROM clean_order_items;

SELECT COUNT(*) AS fact_orders_rows FROM fact_orders;

SELECT ROUND(SUM(items_value + freight_total),2) AS items_plus_freight,
       ROUND(SUM(payment_total),2)               AS payments
FROM fact_orders WHERE order_status = 'delivered';
