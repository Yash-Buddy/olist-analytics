SELECT 'orders'      AS tbl, COUNT(*) AS n FROM clean_orders
UNION ALL SELECT 'customers',   COUNT(*) FROM clean_customers
UNION ALL SELECT 'order_items', COUNT(*) FROM clean_order_items
UNION ALL SELECT 'payments',    COUNT(*) FROM clean_payments
UNION ALL SELECT 'reviews',     COUNT(*) FROM clean_reviews
UNION ALL SELECT 'products',    COUNT(*) FROM clean_products
UNION ALL SELECT 'sellers',     COUNT(*) FROM clean_sellers
UNION ALL SELECT 'geolocation', COUNT(*) FROM clean_geolocation;

SELECT order_status, COUNT(*) AS n FROM clean_orders GROUP BY order_status ORDER BY n DESC;

SELECT COUNT(*) AS items_without_order
FROM clean_order_items i LEFT JOIN clean_orders o ON i.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS orders_with_multiple_payment_rows
FROM (SELECT order_id FROM clean_payments GROUP BY order_id HAVING COUNT(*) > 1) x;
