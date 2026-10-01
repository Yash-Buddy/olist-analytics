import mysql.connector, json, getpass, os
from decimal import Decimal

Q = {
"kpis": """
  SELECT ROUND((SELECT SUM(price) FROM fact_order_items)) AS revenue,
         (SELECT COUNT(*) FROM fact_orders) AS orders,
         (SELECT COUNT(DISTINCT customer_unique_id) FROM clean_customers) AS customers,
         ROUND((SELECT AVG(review_score) FROM fact_orders), 2) AS avg_review
""",
"monthly_revenue": """
  SELECT CONCAT(year, '-', LPAD(month, 2, '0')) AS label, ROUND(revenue) AS value,
         orders, mom_growth_pct
  FROM vw_monthly_revenue
  WHERE year * 100 + month BETWEEN 201701 AND 201808
  ORDER BY year, month
""",
"top_categories": """
  SELECT category AS label, ROUND(revenue) AS value
  FROM vw_abc ORDER BY revenue DESC LIMIT 10
""",
"categories_by_year": """
  SELECT year, category, ROUND(revenue) AS revenue, rnk
  FROM vw_top_categories_by_year ORDER BY year, rnk
""",
"rfm_segments": """
  SELECT segment AS label, COUNT(*) AS value, ROUND(AVG(monetary)) AS avg_spend
  FROM vw_rfm_segments GROUP BY segment ORDER BY value DESC
""",
"cohort": """
  SELECT c.cohort, c.month_index,
         ROUND(c.customers * 100 / s.customers, 2) AS retention_pct
  FROM vw_cohort c
  JOIN (SELECT cohort, customers FROM vw_cohort WHERE month_index = 0) s
    ON c.cohort = s.cohort
  WHERE c.cohort BETWEEN '2017-01-01' AND '2018-03-01' AND c.month_index BETWEEN 1 AND 12
  ORDER BY c.cohort, c.month_index
""",
"abc": """
  SELECT abc_class AS label, COUNT(*) AS value, ROUND(SUM(revenue)) AS revenue
  FROM vw_abc GROUP BY abc_class ORDER BY abc_class
""",
"seller_quartiles": """
  SELECT CONCAT('Q', delay_quartile) AS label, ROUND(AVG(avg_delay_days), 1) AS value,
         COUNT(*) AS sellers
  FROM vw_seller_delivery GROUP BY delay_quartile ORDER BY delay_quartile
""",
}

conn = mysql.connector.connect(host="localhost", user="root",
                               password=getpass.getpass("MySQL password: "), database="olist")
fix = lambda v: float(v) if isinstance(v, Decimal) else v
for name, sql in Q.items():
    cur = conn.cursor()
    cur.execute(sql)
    cols = [c[0] for c in cur.description]
    rows = [dict(zip(cols, map(fix, r))) for r in cur.fetchall()]
    json.dump(rows, open(f"viz/data/{name}.json", "w"), indent=2, default=str)
    print(f"{len(rows):>4} rows -> viz/data/{name}.json")
