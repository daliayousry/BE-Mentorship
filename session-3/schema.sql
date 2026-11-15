-- Session 3 — E-commerce sample schema (PostgreSQL)
-- Entities: Category, Product, Customer, Order, Order_details
-- "order" is a reserved word in SQL, so the table is named orders.
--
-- Create the database once, then run this file inside it:
--   createdb ecommerce
--   psql -d ecommerce -f schema.sql

CREATE TABLE category (
  category_id   INT           GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  category_name VARCHAR(100)  NOT NULL,
  CONSTRAINT uq_category_name UNIQUE (category_name)
);

CREATE TABLE product (
  product_id     INT            GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  category_id    INT            NOT NULL,
  name           VARCHAR(150)   NOT NULL,
  description    TEXT           NULL,
  price          NUMERIC(10, 2) NOT NULL,
  stock_quantity INT            NOT NULL DEFAULT 0,
  CONSTRAINT fk_product_category
    FOREIGN KEY (category_id) REFERENCES category (category_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_product_price CHECK (price >= 0),
  CONSTRAINT chk_product_stock CHECK (stock_quantity >= 0)
);

CREATE INDEX idx_product_category ON product (category_id);

CREATE TABLE customer (
  customer_id INT           GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name  VARCHAR(80)   NOT NULL,
  last_name   VARCHAR(80)   NOT NULL,
  email       VARCHAR(255)  NOT NULL,
  password    VARCHAR(255)  NOT NULL,  -- store a hash (bcrypt/argon2), never plain text
  CONSTRAINT uq_customer_email UNIQUE (email)
);

CREATE TABLE orders (
  order_id     INT            GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id  INT            NOT NULL,
  order_date   TIMESTAMPTZ    NOT NULL DEFAULT now(),
  -- Denormalized: derivable from SUM(order_details.quantity * unit_price).
  -- Kept here so reports don't need to join/aggregate the details table.
  total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);

CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_orders_date ON orders (order_date);

CREATE TABLE order_details (
  order_detail_id INT            GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id        INT            NOT NULL,
  product_id      INT            NOT NULL,
  quantity        INT            NOT NULL,
  -- Snapshot of the product price at purchase time (product.price can change later).
  unit_price      NUMERIC(10, 2) NOT NULL,
  CONSTRAINT uq_order_product UNIQUE (order_id, product_id),
  CONSTRAINT fk_order_details_order
    FOREIGN KEY (order_id) REFERENCES orders (order_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_order_details_product
    FOREIGN KEY (product_id) REFERENCES product (product_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_order_details_quantity CHECK (quantity > 0)
);

CREATE INDEX idx_order_details_product ON order_details (product_id);
