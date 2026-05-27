

-- Пользователь sa
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'sa') THEN
        CREATE ROLE sa WITH LOGIN SUPERUSER PASSWORD 'De_05';
    ELSE
        ALTER ROLE sa WITH LOGIN SUPERUSER PASSWORD 'De_05';
    END IF;
END
$$;

-- Функция генерации случайного пароля (5 символов)
CREATE OR REPLACE FUNCTION generate_random_password(len INT DEFAULT 5)
RETURNS TEXT AS $$
DECLARE
    chars  TEXT := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i      INT;
BEGIN
    FOR i IN 1..len LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::INT, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Создание пользователей user1..user10
--         Пароли сохраняется во временную таблицу
CREATE TEMP TABLE temp_users (username TEXT, password TEXT);

DO $$
DECLARE
    i     INT;
    uname TEXT;
    pwd   TEXT;
BEGIN
    FOR i IN 1..10 LOOP
        uname := 'user' || i;
        pwd   := generate_random_password(5);

        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = uname) THEN
            EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', uname, pwd);
        ELSE
            EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', uname, pwd);
        END IF;

        INSERT INTO temp_users VALUES (uname, pwd);
    END LOOP;
END
$$;
