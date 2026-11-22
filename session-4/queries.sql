-- Session 4 — Search & recommendation queries (PostgreSQL)
-- Runs against the Session 3 e-commerce schema: ../session-3/schema.sql

-- ---------------------------------------------------------------------------
-- 1. Search for all products with the word "camera" in the name or description.
--    ILIKE = case-insensitive LIKE, so "Camera", "CAMERA" and "camera" all match.
--    description is nullable: NULL ILIKE ... is NULL (not true), so those rows
--    simply fall back to the name check — no COALESCE needed.
-- ---------------------------------------------------------------------------
SELECT
  p.product_id,
  p.name,
  p.description,
  p.price
FROM product p
WHERE p.name        ILIKE '%camera%'
   OR p.description ILIKE '%camera%'
ORDER BY p.name;

-- Variant A — match "camera" as a whole word only.
--   '%camera%' also matches "cameraman" or "camerawork". The regex word
--   boundaries \m (start of word) and \M (end of word) avoid that.
--   Note: this also stops matching the plural "cameras".
SELECT p.product_id, p.name, p.description, p.price
FROM product p
WHERE p.name        ~* '\mcamera\M'
   OR p.description ~* '\mcamera\M'
ORDER BY p.name;

-- Variant B — full-text search (handles plurals via stemming, ranks results).
--   "camera" and "cameras" both stem to "camera". A name match is weighted
--   higher (A) than a description match (B).
--   Leading '%...%' patterns can't use a normal B-tree index, so on a big
--   table either add a pg_trgm GIN index for ILIKE:
--     CREATE EXTENSION IF NOT EXISTS pg_trgm;
--     CREATE INDEX idx_product_name_trgm ON product USING gin (name gin_trgm_ops);
--     CREATE INDEX idx_product_desc_trgm ON product USING gin (description gin_trgm_ops);
--   or a GIN index on the tsvector expression below.
SELECT
  p.product_id,
  p.name,
  p.description,
  p.price,
  ts_rank(doc.tsv, q.query) AS relevance
FROM product p
CROSS JOIN LATERAL (
  SELECT setweight(to_tsvector('english', p.name), 'A')
      || setweight(to_tsvector('english', coalesce(p.description, '')), 'B') AS tsv
) doc
CROSS JOIN plainto_tsquery('english', 'camera') AS q(query)
WHERE doc.tsv @@ q.query
ORDER BY relevance DESC, p.name;

-- ---------------------------------------------------------------------------
-- 2. Recommend popular products to a customer based on the categories of the
--    products they've purchased, excluding the products already purchased.
--    The customer's purchases come from order_details + orders (there is no
--    separate customer-history table in this schema).
--      * first IN      — categories of the products this customer bought
--      * NOT IN        — drop products this customer already bought
--                        (safe here: order_details.product_id is NOT NULL)
--      * ORDER BY      — most popular first = total units sold to everyone
--    Replace 1 with the wanted customer_id.
-- ---------------------------------------------------------------------------
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
