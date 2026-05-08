BEGIN;

CREATE INDEX IF NOT EXISTS idx_orders_customer_created_at
  ON app.orders (customer_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id
  ON app.order_items (product_id);

CREATE INDEX IF NOT EXISTS idx_inventory_movements_product_created_at
  ON app.inventory_movements (product_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_outbox_events_unpublished
  ON app.outbox_events (published_at)
  WHERE published_at IS NULL;

CREATE OR REPLACE VIEW app.order_summary AS
SELECT
  o.id,
  o.order_reference,
  c.email,
  c.full_name,
  o.status,
  o.total_amount,
  o.created_at,
  COUNT(oi.*) AS line_count,
  SUM(oi.quantity) AS item_count
FROM app.orders o
JOIN app.customers c ON c.id = o.customer_id
JOIN app.order_items oi ON oi.order_id = o.id
GROUP BY o.id, c.email, c.full_name;

CREATE OR REPLACE VIEW app.current_inventory AS
SELECT
  p.sku,
  p.name,
  COALESCE(SUM(
    CASE im.movement_type
      WHEN 'in' THEN im.quantity
      WHEN 'released' THEN im.quantity
      WHEN 'out' THEN -im.quantity
      WHEN 'reserved' THEN -im.quantity
    END
  ), 0) AS available_units
FROM app.products p
LEFT JOIN app.inventory_movements im ON im.product_id = p.id
GROUP BY p.sku, p.name;

COMMIT;