# Session 4 — Search & Recommendation Queries

Uses the same e-commerce database as [Session 3](../session-3/README.md) ([schema.sql](../session-3/schema.sql)).

- **Queries:** [queries.sql](queries.sql)

## 1. Search products for "camera"

Find every product whose `name` or `description` contains "camera".

```sql
SELECT p.product_id, p.name, p.description, p.price
FROM product p
WHERE p.name        ILIKE '%camera%'
   OR p.description ILIKE '%camera%'
ORDER BY p.name;
```

- `ILIKE` makes the match case-insensitive ("Camera", "CAMERA").
- `description` can be `NULL`; `NULL ILIKE ...` is not true, so those rows are matched on the name only.
- `queries.sql` also has two variants:
  - **Whole word only** (`~* '\mcamera\M'`): skips "cameraman", but also skips the plural "cameras".
  - **Full-text search** (`to_tsvector` / `plainto_tsquery`): matches plurals through stemming and ranks name matches above description matches.
- A leading `%` stops PostgreSQL from using a normal B-tree index. On a large table, add a `pg_trgm` GIN index (for `ILIKE`) or a GIN index on the tsvector (for full-text search).

## 2. Recommend popular products in the same category

Recommend products to a customer from the categories of the products they've purchased, **excluding products they've already purchased**, most popular first.

The customer's purchases come from `order_details` joined to `orders`, because the schema has no separate customer-history table.

```sql
-- Replace 1 with the wanted customer_id.
SELECT p.product_id, p.name AS product_name, p.category_id
FROM product p
WHERE p.category_id IN (
  SELECT DISTINCT category_id
  FROM product
  WHERE product_id IN (
    SELECT od.product_id
    FROM order_details od
    JOIN orders o ON o.order_id = od.order_id
    WHERE o.customer_id = 1
  )
)
AND p.product_id NOT IN (
  SELECT od.product_id
  FROM order_details od
  JOIN orders o ON o.order_id = od.order_id
  WHERE o.customer_id = 1
)
ORDER BY (
  SELECT COALESCE(SUM(od.quantity), 0)
  FROM order_details od
  WHERE od.product_id = p.product_id
) DESC;
```

- **First `IN`:** the categories of the products this customer has bought.
- **`NOT IN`:** removes the products this customer has already bought. It's safe here because `order_details.product_id` is `NOT NULL`.
- **`ORDER BY`:** puts the most popular products first, by total units sold to all customers.
