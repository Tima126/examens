-- ============================================================
-- Создаёт: таблицу Users, шифрует пароли
-- ============================================================


CREATE EXTENSION IF NOT EXISTS pgcrypto;

--  таблица Users
CREATE TABLE IF NOT EXISTS Users (
    id                 SERIAL PRIMARY KEY,
    username           VARCHAR(50)  NOT NULL UNIQUE,
    password           VARCHAR(255) NOT NULL DEFAULT '********',
    password_encrypted BYTEA,
    created_at         TIMESTAMP DEFAULT NOW()
);


-- встывка пользователей и зашифровываем пароли

DO $$
DECLARE
    encrypt_key TEXT := 'SecretKey_05';
BEGIN
    -- Вставка user1..user10 
    INSERT INTO Users (username, password, password_encrypted) VALUES
        ('user1',  '********', pgp_sym_encrypt('cwnxZ', encrypt_key)),
        ('user2',  '********', pgp_sym_encrypt('v1flC', encrypt_key)),
        ('user3',  '********', pgp_sym_encrypt('l6Ffq', encrypt_key)),
        ('user4',  '********', pgp_sym_encrypt('jmkZq', encrypt_key)),
        ('user5',  '********', pgp_sym_encrypt('PUcti', encrypt_key)),
        ('user6',  '********', pgp_sym_encrypt('c3kEJ', encrypt_key)),
        ('user7',  '********', pgp_sym_encrypt('cryhy', encrypt_key)),
        ('user8',  '********', pgp_sym_encrypt('FfG6O', encrypt_key)),
        ('user9',  '********', pgp_sym_encrypt('1l34a', encrypt_key)),
        ('user10', '********', pgp_sym_encrypt('MDZAV', encrypt_key))
    ON CONFLICT (username) DO UPDATE
        SET password           = '********',
            password_encrypted = EXCLUDED.password_encrypted;

    RAISE NOTICE 'Users inserted and encrypted.';
END $$;

-- Проверка: таблица со скрытыми паролями
SELECT id, username, password, created_at FROM Users ORDER BY id;

-- декод паролей users --
SELECT
    id,
    username,
    pgp_sym_decrypt(password_encrypted, 'SecretKey_05') AS password_decrypted,
    created_at
FROM Users
ORDER BY id;