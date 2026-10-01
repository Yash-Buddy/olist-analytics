SELECT month_index, SUM(customers) AS customers
FROM vw_cohort GROUP BY month_index ORDER BY month_index LIMIT 4;

SELECT abc_class, COUNT(*) AS categories, ROUND(SUM(revenue)) AS revenue
FROM vw_abc GROUP BY abc_class ORDER BY abc_class;

SELECT delay_quartile, COUNT(*) AS sellers, ROUND(AVG(avg_delay_days),1) AS avg_delay
FROM vw_seller_delivery GROUP BY delay_quartile ORDER BY delay_quartile;
