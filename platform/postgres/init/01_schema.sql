CREATE SCHEMA IF NOT EXISTS commerce;

CREATE TABLE IF NOT EXISTS commerce.customers (
    customer_id        BIGINT PRIMARY KEY,
    first_name         TEXT NOT NULL,
    last_name          TEXT NOT NULL,
    email              TEXT NOT NULL UNIQUE,
    country_code       CHAR(2) NOT NULL,
    marketing_consent  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS commerce.products (
    product_id     BIGINT PRIMARY KEY,
    sku            TEXT NOT NULL UNIQUE,
    product_name   TEXT NOT NULL,
    category       TEXT NOT NULL,
    unit_price     NUMERIC(10, 2) NOT NULL,
    active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS commerce.orders (
    order_id       BIGINT PRIMARY KEY,
    customer_id    BIGINT NOT NULL REFERENCES commerce.customers(customer_id),
    order_status   TEXT NOT NULL,
    order_ts       TIMESTAMP NOT NULL,
    country_code   CHAR(2) NOT NULL
);

CREATE TABLE IF NOT EXISTS commerce.order_items (
    order_item_id  BIGINT PRIMARY KEY,
    order_id       BIGINT NOT NULL REFERENCES commerce.orders(order_id),
    product_id     BIGINT NOT NULL REFERENCES commerce.products(product_id),
    quantity       INTEGER NOT NULL,
    unit_price     NUMERIC(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS commerce.payments (
    payment_id      BIGINT PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES commerce.orders(order_id),
    payment_status  TEXT NOT NULL,
    payment_method  TEXT NOT NULL,
    amount          NUMERIC(10, 2) NOT NULL,
    payment_ts      TIMESTAMP NOT NULL
);