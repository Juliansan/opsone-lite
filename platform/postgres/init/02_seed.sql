INSERT INTO commerce.customers
(customer_id, first_name, last_name, email, country_code, marketing_consent, created_at)
VALUES
(1, 'Ana', 'Garcia', 'ana.garcia@example.com', 'ES', TRUE,  '2026-05-01 09:00:00'),
(2, 'Marc', 'Dubois', 'marc.dubois@example.com', 'FR', FALSE, '2026-05-01 10:00:00'),
(3, 'Sofia', 'Rossi', 'sofia.rossi@example.com', 'IT', TRUE,  '2026-05-02 11:00:00'),
(4, 'Joao', 'Silva', 'joao.silva@example.com', 'PT', TRUE,  '2026-05-02 12:00:00'),
(5, 'Emma', 'Muller', 'emma.muller@example.com', 'DE', FALSE, '2026-05-03 13:00:00')
ON CONFLICT (customer_id) DO NOTHING;

INSERT INTO commerce.products
(product_id, sku, product_name, category, unit_price, active, created_at)
VALUES
(101, 'TSHIRT-BLK-M', 'Black T-Shirt M', 'apparel', 19.99, TRUE, '2026-05-01 08:00:00'),
(102, 'TSHIRT-WHT-M', 'White T-Shirt M', 'apparel', 18.99, TRUE, '2026-05-01 08:00:00'),
(103, 'HOODIE-BLK-L', 'Black Hoodie L', 'apparel', 49.99, TRUE, '2026-05-01 08:00:00'),
(104, 'CAP-RED-OS',   'Red Cap',        'accessory', 14.99, TRUE, '2026-05-01 08:00:00')
ON CONFLICT (product_id) DO NOTHING;

INSERT INTO commerce.orders
(order_id, customer_id, order_status, order_ts, country_code)
VALUES
(1001, 1, 'completed', '2026-05-10 09:15:00', 'ES'),
(1002, 2, 'completed', '2026-05-10 10:20:00', 'FR'),
(1003, 3, 'payment_failed', '2026-05-11 12:05:00', 'IT'),
(1004, 1, 'completed', '2026-05-12 14:30:00', 'ES'),
(1005, 4, 'cancelled', '2026-05-12 16:45:00', 'PT')
ON CONFLICT (order_id) DO NOTHING;

INSERT INTO commerce.order_items
(order_item_id, order_id, product_id, quantity, unit_price)
VALUES
(1, 1001, 101, 2, 19.99),
(2, 1001, 104, 1, 14.99),
(3, 1002, 103, 1, 49.99),
(4, 1003, 102, 1, 18.99),
(5, 1004, 101, 1, 19.99),
(6, 1004, 103, 1, 49.99),
(7, 1005, 104, 2, 14.99)
ON CONFLICT (order_item_id) DO NOTHING;

INSERT INTO commerce.payments
(payment_id, order_id, payment_status, payment_method, amount, payment_ts)
VALUES
(5001, 1001, 'paid', 'card', 54.97, '2026-05-10 09:16:00'),
(5002, 1002, 'paid', 'paypal', 49.99, '2026-05-10 10:22:00'),
(5003, 1003, 'failed', 'card', 18.99, '2026-05-11 12:06:00'),
(5004, 1004, 'paid', 'card', 69.98, '2026-05-12 14:32:00'),
(5005, 1005, 'refunded', 'card', 29.98, '2026-05-12 17:00:00')
ON CONFLICT (payment_id) DO NOTHING;