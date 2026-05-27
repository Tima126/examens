#!/bin/bash
# ============================================================
# setup_databases.sh
# Запускается ПОСЛЕ docker compose up
# Создаёт BD, BD1..BD10 и настраивает права
# ============================================================

PG_USER="postgres"
CONTAINER="Server_05"
ENCRYPT_KEY="SecretKey_05"

echo ""
echo "============================================"
echo " Настройка баз данных в контейнере $CONTAINER"
echo "============================================"

# Функция выполнения SQL внутри контейнера
psql_exec() {
    local db="${1:-postgres}"
    local sql="$2"
    docker exec -i "$CONTAINER" psql -U "$PG_USER" -d "$db" -c "$sql" -t -q
}

# ШАГ 1. Создаём базы данных
echo ""
echo "[1/4] Создание баз данных BD, BD1..BD10..."

for db in BD BD1 BD2 BD3 BD4 BD5 BD6 BD7 BD8 BD9 BD10; do
    EXISTS=$(docker exec -i "$CONTAINER" psql -U "$PG_USER" -d postgres \
        -t -q -c "SELECT 1 FROM pg_database WHERE datname = '$db';")
    if echo "$EXISTS" | grep -q 1; then
        echo "  База '$db' уже существует — пропуск."
    else
        docker exec -i "$CONTAINER" psql -U "$PG_USER" -d postgres \
            -c "CREATE DATABASE \"$db\";" -q
        echo "  База '$db' создана."
    fi
done

# ШАГ 2. Создаём таблицу Users в базе BD + расширение pgcrypto
echo ""
echo "[2/4] Создание таблицы Users и включение pgcrypto..."

psql_exec "BD" "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

psql_exec "BD" "
CREATE TABLE IF NOT EXISTS Users (
    id                 SERIAL PRIMARY KEY,
    username           VARCHAR(50)  NOT NULL UNIQUE,
    password           VARCHAR(255) NOT NULL,
    password_encrypted BYTEA,
    created_at         TIMESTAMP DEFAULT NOW()
);
"
echo "  Таблица Users готова."

# ШАГ 3. Заполняем таблицу Users и шифруем пароли
echo ""
echo "[3/4] Заполнение таблицы Users и шифрование паролей..."

# Получаем пользователей из temp_users (они живут только в сессии init.sql,
# поэтому читаем напрямую из pg_roles и генерируем пароли заново)
for i in $(seq 1 10); do
    UNAME="user$i"
    PWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c5)

    # Обновляем пароль пользователя
    docker exec -i "$CONTAINER" psql -U "$PG_USER" -d postgres \
        -c "ALTER ROLE $UNAME WITH PASSWORD '$PWD';" -q

    # Вставляем в таблицу Users с шифрованием
    psql_exec "BD" "
    INSERT INTO Users (username, password, password_encrypted)
    VALUES ('$UNAME', '********', pgp_sym_encrypt('$PWD', '$ENCRYPT_KEY'))
    ON CONFLICT (username) DO UPDATE
        SET password           = '********',
            password_encrypted = pgp_sym_encrypt('$PWD', '$ENCRYPT_KEY');
    "

    echo "  $UNAME — пароль зашифрован и сохранён."
done

# ШАГ 4. Настройка прав: userN -> только BDN
echo ""
echo "[4/4] Настройка прав доступа..."

for i in $(seq 1 10); do
    UNAME="user$i"
    DB="BD$i"

    psql_exec "$DB" "REVOKE CONNECT ON DATABASE \"$DB\" FROM PUBLIC;"
    psql_exec "$DB" "GRANT CONNECT ON DATABASE \"$DB\" TO $UNAME;"
    psql_exec "$DB" "GRANT USAGE ON SCHEMA public TO $UNAME;"
    psql_exec "$DB" "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $UNAME;"
    psql_exec "$DB" "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $UNAME;"
    psql_exec "$DB" "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $UNAME;"
    psql_exec "$DB" "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $UNAME;"

    echo "  $UNAME -> $DB : права настроены."
done

# ИТОГ: показываем таблицу Users с расшифрованными паролями
echo ""
echo "============================================"
echo " Готово! Таблица Users (расшифрованные пароли):"
echo "============================================"

docker exec -i "$CONTAINER" psql -U "$PG_USER" -d BD \
    -c "SELECT id, username, pgp_sym_decrypt(password_encrypted, '$ENCRYPT_KEY') AS password_decrypted, created_at FROM Users ORDER BY id;"

echo ""
echo "  Подключение в pgAdmin:"
echo "  Host     : localhost"
echo "  Port     : 5432"
echo "  Username : sa"
echo "  Password : De_05"
echo "============================================"
