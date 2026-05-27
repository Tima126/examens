-- ============================================================
-- МОДУЛЬ 6: Архивация заказов за указанный месяц (ИСПРАВЛЕННЫЙ)
-- ============================================================

DO $$
DECLARE
    v_year      INTEGER := 2024;        -- Укажите год
    v_month     INTEGER := 5;           -- Укажите месяц (1-12)
    v_archive_table TEXT;
    v_archive_items_table TEXT;
    v_start_date DATE;
    v_end_date   DATE;
    v_count      INTEGER;
BEGIN
    -- Формируем имя архивной таблицы: Orders_2024_05
    v_archive_table := 'Orders_' || TO_CHAR(TO_DATE(v_year || '-' || v_month || '-01', 'YYYY-MM-DD'), 'YYYY_MM');
    v_archive_items_table := v_archive_table || '_items';
    
    -- Границы месяца
    v_start_date := DATE(v_year || '-' || v_month || '-01');
    v_end_date   := (v_start_date + INTERVAL '1 month')::DATE;
    
    RAISE NOTICE 'Архивация заказов за период с % по % в таблицу %', 
        v_start_date, v_end_date, v_archive_table;
    
    -- 1. Создаём архивную таблицу для заказов
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I (
            LIKE Orders INCLUDING ALL
        )', v_archive_table);
    
    -- 2. Создаём архивную таблицу для позиций заказов
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I (
            LIKE Order_Items INCLUDING ALL
        )', v_archive_items_table);
    
    -- 3. Переносим данные из Orders в архивную таблицу
    EXECUTE format('
        INSERT INTO %I 
        SELECT * FROM Orders 
        WHERE order_date >= %L AND order_date < %L',
        v_archive_table, v_start_date, v_end_date);
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Скопировано заказов: %', v_count;
    
    -- 4. Если заказы скопированы, переносим их позиции
    IF v_count > 0 THEN
        EXECUTE format('
            INSERT INTO %I (id_order_item, id_order, id_product, quantity, price, amount)
            SELECT oi.*
            FROM Order_Items oi
            INNER JOIN %I oa ON oi.id_order = oa.id_order',
            v_archive_items_table, v_archive_table);
        
        GET DIAGNOSTICS v_count = ROW_COUNT;
        RAISE NOTICE 'Скопировано позиций заказов: %', v_count;
        
        -- 5. Удаляем перенесённые заказы из исходной таблицы Orders
        --    (связанные записи в Order_Items удалятся автоматически благодаря ON DELETE CASCADE)
        DELETE FROM Orders 
        WHERE order_date >= v_start_date AND order_date < v_end_date;
        
        GET DIAGNOSTICS v_count = ROW_COUNT;
        RAISE NOTICE 'Удалено заказов из исходной таблицы: %', v_count;
        
        -- Проверяем, что позиции удалились автоматически
        DECLARE
            v_remaining_items INTEGER;
        BEGIN
            EXECUTE format('
                SELECT COUNT(*) FROM %I WHERE id_order IN (SELECT id_order FROM %I)',
                v_archive_items_table, v_archive_table) INTO v_remaining_items;
            RAISE NOTICE 'Позиций заказов в архиве: %', v_remaining_items;
        END;
        
    ELSE
        RAISE NOTICE 'Нет заказов за указанный период. Ничего не архивировано.';
    END IF;
    
    RAISE NOTICE 'Архивация завершена. Архивные таблицы: % и %', 
        v_archive_table, v_archive_items_table;
        
END $$;

-- ============================================================
-- ПРОВЕРКА РЕЗУЛЬТАТА
-- ============================================================

-- 1. Список созданных архивных таблиц
SELECT tablename 
FROM pg_tables 
WHERE tablename LIKE 'Orders\_%' ESCAPE '\'
ORDER BY tablename;

-- 2. Проверить заказы в исходной таблице (должны отсутствовать за май 2024)
SELECT 'Остатки в исходной таблице Orders:' as info;
SELECT * FROM Orders WHERE order_date BETWEEN '2024-05-01' AND '2024-05-31';

-- 3. Проверить заказы в архивной таблице
DO $$
DECLARE
    v_archive_table TEXT := 'Orders_2024_05';
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM pg_tables WHERE tablename = v_archive_table
    ) INTO v_exists;
    
    IF v_exists THEN
        EXECUTE format('
            SELECT ''Заказы в архивной таблице '' || %L || '':'' as info;
            SELECT * FROM %I', v_archive_table, v_archive_table);
    ELSE
        RAISE NOTICE 'Архивная таблица % не существует', v_archive_table;
    END IF;
END $$;

-- 4. Проверить позиции заказов в архивной таблице
DO $$
DECLARE
    v_archive_items_table TEXT := 'Orders_2024_05_items';
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM pg_tables WHERE tablename = v_archive_items_table
    ) INTO v_exists;
    
    IF v_exists THEN
        EXECUTE format('
            SELECT ''Позиции заказов в архивной таблице '' || %L || '':'' as info;
            SELECT * FROM %I LIMIT 10', v_archive_items_table, v_archive_items_table);
    ELSE
        RAISE NOTICE 'Архивная таблица % не существует', v_archive_items_table;
    END IF;
END $$;

-- ============================================================
-- ФУНКЦИЯ ДЛЯ АВТОМАТИЧЕСКОЙ АРХИВАЦИИ ЗА ТЕКУЩИЙ МЕСЯЦ
-- ============================================================
CREATE OR REPLACE FUNCTION archive_orders_for_month(p_year INTEGER, p_month INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_archive_table TEXT;
    v_archive_items_table TEXT;
    v_start_date DATE;
    v_end_date DATE;
    v_count INTEGER;
BEGIN
    v_archive_table := 'Orders_' || TO_CHAR(TO_DATE(p_year || '-' || p_month || '-01', 'YYYY-MM-DD'), 'YYYY_MM');
    v_archive_items_table := v_archive_table || '_items';
    v_start_date := DATE(p_year || '-' || p_month || '-01');
    v_end_date := (v_start_date + INTERVAL '1 month')::DATE;
    
    -- Создаём архивные таблицы
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I (LIKE Orders INCLUDING ALL)', v_archive_table);
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I (LIKE Order_Items INCLUDING ALL)', v_archive_items_table);
    
    -- Копируем заказы
    EXECUTE format('
        INSERT INTO %I SELECT * FROM Orders WHERE order_date >= %L AND order_date < %L',
        v_archive_table, v_start_date, v_end_date);
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    IF v_count > 0 THEN
        -- Копируем позиции
        EXECUTE format('
            INSERT INTO %I SELECT oi.* FROM Order_Items oi 
            INNER JOIN %I oa ON oi.id_order = oa.id_order',
            v_archive_items_table, v_archive_table);
        
        -- Удаляем из исходных таблиц
        DELETE FROM Orders WHERE order_date >= v_start_date AND order_date < v_end_date;
        
        RETURN format('Заархивировано %d заказов за %s-%s в таблицу %s', 
            v_count, p_year, p_month, v_archive_table);
    ELSE
        RETURN format('Нет заказов за %s-%s для архивации', p_year, p_month);
    END IF;
END;
$$;

-- Пример вызова функции:
-- SELECT archive_orders_for_month(2024, 5);
-- SELECT archive_orders_for_month(EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER);