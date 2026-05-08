BEGIN;

INSERT INTO app.customers (email, full_name, tier)
VALUES
  ('alice@example.com', 'Alice Novak', 'gold'),
  ('bob@example.com', 'Bob Svoboda', 'silver'),
  ('carol@example.com', 'Carol Dvorak', 'bronze')
ON CONFLICT (email) DO UPDATE
SET
  full_name = EXCLUDED.full_name,
  tier = EXCLUDED.tier;

INSERT INTO app.products (sku, name, price)
VALUES
  ('SKU-KEYBOARD', 'Mechanical Keyboard', 89.00),
  ('SKU-MOUSE', 'Wireless Mouse', 49.00),
  ('SKU-DOCKER-BOOK', 'Docker Deep Dive Book', 39.00)
ON CONFLICT (sku) DO UPDATE
SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  active = true;

DO
\$\$
DECLARE
  order_alice bigint;
  order_bob bigint;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM app.orders WHERE order_reference = 'ORD-1001') THEN
    INSERT INTO app.orders (order_reference, customer_id, status, paid_at)
    VALUES (
      'ORD-1001',
      (SELECT id FROM app.customers WHERE email = 'alice@example.com'),
      'paid',
      now()
    )
    RETURNING id INTO order_alice;

    INSERT INTO app.order_items (order_id, line_no, product_id, quantity, unit_price)
    VALUES
      (order_alice, 1, (SELECT id FROM app.products WHERE sku = 'SKU-KEYBOARD'), 1, 89.00),
      (order_alice, 2, (SELECT id FROM app.products WHERE sku = 'SKU-DOCKER-BOOK'), 1, 39.00);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM app.orders WHERE order_reference = 'ORD-1002') THEN
    INSERT INTO app.orders (order_reference, customer_id, status, paid_at)
    VALUES (
      'ORD-1002',
      (SELECT id FROM app.customers WHERE email = 'bob@example.com'),
      'paid',
      now()
    )
    RETURNING id INTO order_bob;

    INSERT INTO app.order_items (order_id, line_no, product_id, quantity, unit_price)
    VALUES
      (order_bob, 1, (SELECT id FROM app.products WHERE sku = 'SKU-MOUSE'), 2, 49.00);
  END IF;
END
\$\$;

UPDATE app.orders o
SET total_amount = totals.total_amount
FROM (
  SELECT order_id, SUM(quantity * unit_price)::numeric(10, 2) AS total_amount
  FROM app.order_items
  GROUP BY order_id
) totals
WHERE totals.order_id = o.id;

INSERT INTO app.inventory_movements (product_id, movement_type, quantity, source_reference)
VALUES
  ((SELECT id FROM app.products WHERE sku = 'SKU-KEYBOARD'), 'in', 20, 'STOCK-IN-KEYBOARD'),
  ((SELECT id FROM app.products WHERE sku = 'SKU-MOUSE'), 'in', 30, 'STOCK-IN-MOUSE'),
  ((SELECT id FROM app.products WHERE sku = 'SKU-DOCKER-BOOK'), 'in', 15, 'STOCK-IN-BOOK'),
  ((SELECT id FROM app.products WHERE sku = 'SKU-KEYBOARD'), 'out', 1, 'ORD-1001-KEYBOARD'),
  ((SELECT id FROM app.products WHERE sku = 'SKU-DOCKER-BOOK'), 'out', 1, 'ORD-1001-BOOK'),
  ((SELECT id FROM app.products WHERE sku = 'SKU-MOUSE'), 'out', 2, 'ORD-1002-MOUSE')
ON CONFLICT (product_id, movement_type, source_reference) DO NOTHING;

INSERT INTO app.outbox_events (aggregate_type, aggregate_id, event_type, payload)
VALUES
  (
    'order',
    'ORD-1001',
    'order.paid',
    jsonb_build_object('order_reference', 'ORD-1001', 'customer_email', 'alice@example.com', 'total_amount', 128.00)
  ),
  (
    'order',
    'ORD-1002',
    'order.paid',
    jsonb_build_object('order_reference', 'ORD-1002', 'customer_email', 'bob@example.com', 'total_amount', 98.00)
  )
ON CONFLICT DO NOTHING;

COMMIT;