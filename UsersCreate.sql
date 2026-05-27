

-- Пользователь sa
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'sa') THEN
        CREATE ROLE sa WITH LOGIN SUPERUSER PASSWORD 'De_05';
    ELSE
        ALTER ROLE sa WITH LOGIN SUPERUSER PASSWORD 'De_05';
    END IF;
END $$;

-- Функция генерации случайного пароля
CREATE OR REPLACE FUNCTION generate_random_password()
RETURNS TEXT AS $$
DECLARE
    chars  TEXT := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i      INT;
BEGIN
    FOR i IN 1..5 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::INT, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Создание user1..user10
DO $$
DECLARE
    i     INT;
    uname TEXT;
    pwd   TEXT;
BEGIN
    FOR i IN 1..10 LOOP
        uname := 'user' || i;
        pwd   := generate_random_password();

        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = uname) THEN
            EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', uname, pwd);
        ELSE
            EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', uname, pwd);
        END IF;

        RAISE NOTICE 'user: % | password: %', uname, pwd;
    END LOOP;
END $$;

-- Проверка
SELECT rolname FROM pg_roles
WHERE rolname IN ('sa','user1','user2','user3','user4','user5',
                      'user6','user7','user8','user9','user10')
ORDER BY rolname;