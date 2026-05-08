-- Otevri dve terminalova okna a v obou se pripoj na primary:
-- docker compose exec postgres-primary psql -U admin -d appdb

-- Session A
BEGIN;
SELECT id, sku, price FROM app.products WHERE sku = 'SKU-KEYBOARD' FOR UPDATE;
UPDATE app.products SET price = price + 5 WHERE sku = 'SKU-KEYBOARD';
-- Necommituj hned. Drz transakci otevrenou.

-- Session B
BEGIN;
UPDATE app.products SET price = price + 1 WHERE sku = 'SKU-KEYBOARD';
-- Tady uvidis cekani na lock.

-- V jine session si mezitim over blokace:
-- SELECT pid, wait_event_type, wait_event, query FROM pg_stat_activity WHERE datname = 'appdb';

-- Pak v Session A:
COMMIT;

-- A v Session B:
COMMIT;