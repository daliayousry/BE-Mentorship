-- Session 3 — Report queries (PostgreSQL)

-- ---------------------------------------------------------------------------
-- 1. Daily report: total revenue for a specific date.
--    Replace '2026-11-14' with the wanted date (or bind it as a parameter).
--    The half-open range (>= day, < day + 1) keeps the query sargable, so it
--    can use idx_orders_date — unlike WHERE order_date::date = '...', which
--    wraps the column in a cast and forces a full scan.
-- ---------------------------------------------------------------------------
SELECT
  o.order_date::date  AS report_date,
  COUNT(*)            AS orders_count,
  SUM(o.total_amount) AS total_revenue
FROM orders o
WHERE o.order_date >= DATE '2026-11-14'
  AND o.order_date <  DATE '2026-11-14' + INTERVAL '1 day'
GROUP BY o.order_date::date;

-- ---------------------------------------------------------------------------
-- 2. Monthly report: top-selling products in a given month.
--    Replace '2026-10-01' with the first day of the wanted month.
--    Revenue uses order_details.unit_price (the price at purchase time),
--    not product.price (the current price).
-- ---------------------------------------------------------------------------
SELECT
  p.product_id,
  p.name                           AS product_name,
  SUM(od.quantity)                 AS units_sold,
  SUM(od.quantity * od.unit_price) AS revenue
FROM order_details od
JOIN orders  o ON o.order_id   = od.order_id
JOIN product p ON p.product_id = od.product_id
WHERE o.order_date >= DATE '2026-10-01'
  AND o.order_date <  DATE '2026-10-01' + INTERVAL '1 month'
GROUP BY p.product_id, p.name
ORDER BY units_sold DESC, revenue DESC
LIMIT 10;

-- ---------------------------------------------------------------------------
-- 3. [Complex] Customers whose orders in the past month total more than $500,
--    with their names and total order amounts.
--    "Past month" = the last month relative to today (rolling window).
--    Grouping by the primary key lets PostgreSQL accept the other customer
--    columns in SELECT (they are functionally dependent on it).
-- ---------------------------------------------------------------------------
SELECT
  c.customer_id,
  c.first_name || ' ' || c.last_name AS customer_name,
  COUNT(o.order_id)                  AS orders_count,
  SUM(o.total_amount)                AS total_spent
FROM customer c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY c.customer_id
HAVING SUM(o.total_amount) > 500
ORDER BY total_spent DESC;

-- Same report for the previous *calendar* month instead of a rolling window:
SELECT
  c.customer_id,
  c.first_name || ' ' || c.last_name AS customer_name,
  SUM(o.total_amount)                AS total_spent
FROM customer c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_date >= date_trunc('month', CURRENT_DATE) - INTERVAL '1 month'
  AND o.order_date <  date_trunc('month', CURRENT_DATE)
GROUP BY c.customer_id
HAVING SUM(o.total_amount) > 500
ORDER BY total_spent DESC;
