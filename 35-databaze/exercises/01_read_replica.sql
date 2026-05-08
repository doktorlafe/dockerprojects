-- Spust na replice:
-- docker compose exec postgres-replica psql -U admin -d appdb -f exercises/01_read_replica.sql

SELECT pg_is_in_recovery() AS replica_mode;

SELECT order_reference, status, total_amount
FROM app.orders
ORDER BY id;

SELECT sku, available_units
FROM app.current_inventory
ORDER BY sku;

-- Tenhle prikaz ma skoncit chybou, protoze replica je read-only.
INSERT INTO app.customers (email, full_name)
VALUES ('should-fail-on-replica@example.com', 'Replica Write Test');