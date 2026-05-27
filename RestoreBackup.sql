-- ============================================================
-- Восстанавливает таблицу Users из последнего снимка бэкапа
-- ============================================================

DO $$
DECLARE
    snap_id    INT;
    row_count  INT;
BEGIN
    -- Берём ID последнего снимка
    SELECT MAX(snapshot_id) INTO snap_id FROM backup_snapshot;

    IF snap_id IS NULL THEN
        RAISE EXCEPTION 'Снимки не найдены! Сначала запустите 05_backup.sql';
    END IF;

    RAISE NOTICE 'Восстановление из снимка id=%', snap_id;

    -- Очищаем текущие данные
    TRUNCATE TABLE Users RESTART IDENTITY CASCADE;

    -- Восстанавливаем из снимка
    INSERT INTO Users (username, password, password_encrypted, created_at)
    SELECT username, password, password_encrypted, created_at
    FROM backup_snapshot
    WHERE snapshot_id = snap_id;

    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE 'Восстановлено строк: %', row_count;
END $$;

-- Проверка результата
SELECT id, username, password, created_at FROM Users ORDER BY id;

-- Расшифрованные пароли
SELECT
    id,
    username,
    pgp_sym_decrypt(password_encrypted, 'SecretKey_05') AS password_decrypted,
    created_at
FROM Users
ORDER BY id;