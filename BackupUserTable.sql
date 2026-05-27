

-- Создаёт резервную копию таблицы Users в виде SQL-скрипта


--  таблица для хранения бэкапов
CREATE TABLE IF NOT EXISTS backups (
    id          SERIAL PRIMARY KEY,
    backup_name VARCHAR(255) NOT NULL,
    backup_data TEXT         NOT NULL,
    created_at  TIMESTAMP    DEFAULT NOW()
);

-- сохраняется всё содержимое Users как SQL INSERT-ы
DO $$
DECLARE
    backup_sql  TEXT := '';
    backup_name TEXT;
    rec         RECORD;
BEGIN
    backup_name := 'backup_BD_' || to_char(NOW(), 'YYYY-MM-DD_HH24-MI-SS');

    -- Заголовок
    backup_sql := '-- Backup of table Users' || chr(10);
    backup_sql := backup_sql || '-- Created: ' || NOW()::TEXT || chr(10);
    backup_sql := backup_sql || 'TRUNCATE TABLE Users RESTART IDENTITY CASCADE;' || chr(10);

    -- Генерируем INSERT для каждой строки
    FOR rec IN SELECT * FROM Users ORDER BY id LOOP
        backup_sql := backup_sql ||
            format(
                'INSERT INTO Users (username, password, password_encrypted, created_at) VALUES (%L, %L, %L, %L);',
                rec.username,
                rec.password,
                encode(rec.password_encrypted, 'base64'),
                rec.created_at
            ) || chr(10);
    END LOOP;

    -- Сохранение бэкап в таблицу backups
    INSERT INTO backups (backup_name, backup_data)
    VALUES (backup_name, backup_sql);

    RAISE NOTICE 'Backup created: %', backup_name;
    RAISE NOTICE 'Rows backed up: %', (SELECT COUNT(*) FROM Users);
END $$;

-- Создаём таблицу-снимок строк для восстановления
CREATE TABLE IF NOT EXISTS backup_snapshot (
    snapshot_id        INT,
    username           VARCHAR(50),
    password           VARCHAR(255),
    password_encrypted BYTEA,
    created_at         TIMESTAMP
);

-- Сохраняем снимок строк Users
INSERT INTO backup_snapshot (snapshot_id, username, password, password_encrypted, created_at)
SELECT
    (SELECT MAX(id) FROM backups),
    username,
    password,
    password_encrypted,
    created_at
FROM Users;

SELECT COUNT(*) FROM Users

-- Показываем список всех бэкапов
SELECT id, backup_name, length(backup_data) AS size_chars, created_at
FROM backups
ORDER BY created_at DESC;




COPY (
    SELECT backup_data 
    FROM backups 
    ORDER BY id DESC 
    LIMIT 1
) TO '/tmp/backup_BD.sql' WITH (FORMAT TEXT);

-- 3. Проверяем, что бэкап создан и сохранён
SELECT 
    id, 
    backup_name, 
    LENGTH(backup_data) AS size_chars,
    created_at
FROM backups 
ORDER BY created_at DESC 
LIMIT 1;