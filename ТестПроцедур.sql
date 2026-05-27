-- ============================================================
-- ТЕСТЫ ДЛЯ ВСЕХ ПРОЦЕДУР И ТРИГГЕРОВ (ИСПРАВЛЕННЫЙ)
-- ============================================================

-- Подготовка: создаём тестовые данные (чистая база)
DO $$
DECLARE
    v_zakazchik1_id INTEGER;
    v_zakazchik2_id INTEGER;
    v_product1_id INTEGER;
    v_product2_id INTEGER;
    v_material1_id INTEGER;
    v_material2_id INTEGER;
    v_material3_id INTEGER;
    v_order1_id INTEGER;
    v_order2_id INTEGER;
    v_order3_id INTEGER;
    v_rec RECORD;
BEGIN
    -- Очистка таблиц (с каскадом)
    TRUNCATE Order_Items CASCADE;
    TRUNCATE Orders CASCADE;
    TRUNCATE Cost_Calculation CASCADE;
    TRUNCATE Specifications CASCADE;
    TRUNCATE Prices CASCADE;
    TRUNCATE Products CASCADE;
    TRUNCATE Materials CASCADE;
    TRUNCATE Zakazchiki CASCADE;
    
    -- Сброс последовательностей
    ALTER SEQUENCE IF EXISTS zakazchiki_id_zakazchik_seq RESTART WITH 1;
    ALTER SEQUENCE IF EXISTS products_id_product_seq RESTART WITH 1;
    ALTER SEQUENCE IF EXISTS materials_id_material_seq RESTART WITH 1;
    ALTER SEQUENCE IF EXISTS orders_id_order_seq RESTART WITH 1;
    ALTER SEQUENCE IF EXISTS order_items_id_order_item_seq RESTART WITH 1;
    ALTER SEQUENCE IF EXISTS specifications_id_spec_seq RESTART WITH 1;
    ALTER SEQUENCE IF EXISTS cost_calculation_id_cost_seq RESTART WITH 1;
    ALTER SEQUENCE IF EXISTS prices_id_price_seq RESTART WITH 1;
    
    -- 1. Заказчики
    INSERT INTO Zakazchiki (name, inn, address, phone, is_salesman, is_buyer) VALUES
        ('ООО "Ромашка"', '770123456789', 'г. Москва, ул. Ленина, 1', '+7(495)111-22-33', FALSE, TRUE)
    RETURNING id_zakazchik INTO v_zakazchik1_id;
    
    INSERT INTO Zakazchiki (name, inn, address, phone, is_salesman, is_buyer) VALUES
        ('ИП Иванов', '500123456789', 'г. Тверь, ул. Пушкина, 10', '+7(4822)33-44-55', TRUE, FALSE)
    RETURNING id_zakazchik INTO v_zakazchik2_id;
    
    -- 2. Продукты
    INSERT INTO Products (name, unit, price) VALUES
        ('Стол письменный', 'шт', 5000.00)
    RETURNING id_product INTO v_product1_id;
    
    INSERT INTO Products (name, unit, price) VALUES
        ('Стул офисный', 'шт', 2500.00)
    RETURNING id_product INTO v_product2_id;
    
    -- 3. Материалы
    INSERT INTO Materials (name, unit, code) VALUES
        ('ДСП', 'м²', 'MAT001')
    RETURNING id_material INTO v_material1_id;
    
    INSERT INTO Materials (name, unit, code) VALUES
        ('Ножки металлические', 'шт', 'MAT002')
    RETURNING id_material INTO v_material2_id;
    
    INSERT INTO Materials (name, unit, code) VALUES
        ('Ткань мебельная', 'м²', 'MAT003')
    RETURNING id_material INTO v_material3_id;
    
    -- 4. Спецификации (нормы расхода)
    INSERT INTO Specifications (id_product, id_material, quantity) VALUES
        (v_product1_id, v_material1_id, 2.5),
        (v_product1_id, v_material2_id, 4),
        (v_product2_id, v_material2_id, 4),
        (v_product2_id, v_material3_id, 0.8);
    
    -- 5. Цены на материалы (для себестоимости) – в Cost_Calculation
    INSERT INTO Cost_Calculation (id_product, id_material, mat_quantity, mat_price, total_cost) VALUES
        (v_product1_id, v_material1_id, 1, 800.00, 800.00),
        (v_product1_id, v_material2_id, 1, 150.00, 150.00),
        (v_product2_id, v_material2_id, 1, 150.00, 150.00),
        (v_product2_id, v_material3_id, 1, 300.00, 300.00);
    
    -- 6. История цен на продукты
    INSERT INTO Prices (id_product, price, date_from, date_to) VALUES
        (v_product1_id, 4800.00, '2024-01-01', '2024-02-28'),
        (v_product1_id, 5000.00, '2024-03-01', NULL),
        (v_product2_id, 2400.00, '2024-01-01', '2024-01-31'),
        (v_product2_id, 2500.00, '2024-02-01', NULL);
    
    -- 7. Заказы
    INSERT INTO Orders (order_number, order_date, id_zakazchik) VALUES
        (1001, '2024-01-15', v_zakazchik1_id)
    RETURNING id_order INTO v_order1_id;
    
    INSERT INTO Orders (order_number, order_date, id_zakazchik) VALUES
        (1002, '2024-02-20', v_zakazchik1_id)
    RETURNING id_order INTO v_order2_id;
    
    INSERT INTO Orders (order_number, order_date, id_zakazchik) VALUES
        (1003, '2024-03-10', v_zakazchik2_id)
    RETURNING id_order INTO v_order3_id;
    
    -- 8. Позиции заказов (триггер автоматически обновит total_amount в Orders)
    INSERT INTO Order_Items (id_order, id_product, quantity, price) VALUES
        (v_order1_id, v_product1_id, 2, 5000.00),   -- 2 стола
        (v_order1_id, v_product2_id, 5, 2500.00),   -- 5 стульев
        (v_order2_id, v_product1_id, 1, 5000.00),   -- 1 стол
        (v_order3_id, v_product2_id, 10, 2500.00);  -- 10 стульев
    
    RAISE NOTICE 'Тестовые данные загружены. заказчик1=%, заказчик2=%, продукт1=%, продукт2=%', 
        v_zakazchik1_id, v_zakazchik2_id, v_product1_id, v_product2_id;
END $$;

-- ============================================================
-- ТЕСТ 1: Процедура GetOrdersStatistics (вывод в консоль)
-- ============================================================
DO $$
DECLARE
    v_zakazchik_id INTEGER;
BEGIN
    RAISE NOTICE E'\n=== ТЕСТ 1: GetOrdersStatistics ===';
    
    -- 1. По всем заказчикам за период
    CALL GetOrdersStatistics('2024-01-01', '2024-03-31');
    
    -- 2. По конкретному заказчику (сначала получаем ID)
    SELECT id_zakazchik INTO v_zakazchik_id 
    FROM Zakazchiki 
    WHERE name = 'ООО "Ромашка"'
    LIMIT 1;
    
    CALL GetOrdersStatistics('2024-01-01', '2024-03-31', v_zakazchik_id);
    
    -- 3. За период без данных
    CALL GetOrdersStatistics('2023-01-01', '2023-12-31');
END $$;

-- ============================================================
-- ТЕСТ 2: Функция GetOrdersStatisticsTable (возвращает таблицу)
-- ============================================================
DO $$
DECLARE
    v_count INTEGER;
    rec RECORD;
BEGIN
    RAISE NOTICE E'\n=== ТЕСТ 2: GetOrdersStatisticsTable ===';
    -- Вызов функции и проверка количества строк
    SELECT COUNT(*) INTO v_count FROM GetOrdersStatisticsTable('2024-01-01', '2024-03-31');
    RAISE NOTICE 'За период 2024-01-01 – 2024-03-31 найдено % заказчиков', v_count;
    
    -- Проверка данных
    FOR rec IN SELECT * FROM GetOrdersStatisticsTable('2024-01-01', '2024-03-31') LOOP
        RAISE NOTICE 'Заказчик: %, заказов: %, сумма: % руб.', 
            rec.zakazchik_name, rec.total_orders, rec.total_amount;
    END LOOP;
    
    -- Проверка фильтра по заказчику
    SELECT COUNT(*) INTO v_count FROM GetOrdersStatisticsTable('2024-01-01', '2024-03-31', 
        (SELECT id_zakazchik FROM Zakazchiki WHERE name = 'ООО "Ромашка"'));
    RAISE NOTICE 'Для ООО "Ромашка" найдено записей: % (должно быть 1)', v_count;
END $$;

-- ============================================================
-- ТЕСТ 3: Функция CalculateProductCost
-- ============================================================
DO $$
DECLARE
    v_product_id INTEGER;
    v_cost NUMERIC(15,2);
    v_product_name TEXT;
BEGIN
    RAISE NOTICE E'\n=== ТЕСТ 3: CalculateProductCost ===';
    SELECT id_product, name INTO v_product_id, v_product_name FROM Products WHERE name = 'Стол письменный' LIMIT 1;
    v_cost := CalculateProductCost(v_product_id, 1);
    RAISE NOTICE 'Себестоимость 1 %: % руб. (ожидается: 2.5*800 + 4*150 = 2000 + 600 = 2600 руб.)', v_product_name, v_cost;
    
    v_cost := CalculateProductCost(v_product_id, 10);
    RAISE NOTICE 'Себестоимость 10 %: % руб. (ожидается 26000 руб.)', v_product_name, v_cost;
    
    -- Проверка для продукта без спецификаций (должен вернуть 0)
    INSERT INTO Products (name, unit, price) VALUES ('Пустой продукт', 'шт', 100) RETURNING id_product INTO v_product_id;
    v_cost := CalculateProductCost(v_product_id, 1);
    RAISE NOTICE 'Себестоимость продукта без спецификаций: % руб. (ожидается 0)', v_cost;
END $$;

-- ============================================================
-- ТЕСТ 4: Триггер CalculateOrderTotal (автообновление суммы заказа)
-- ============================================================
DO $$
DECLARE
    v_order_id INTEGER;
    v_total_before NUMERIC(15,2);
    v_total_after NUMERIC(15,2);
    v_product_id INTEGER;
BEGIN
    RAISE NOTICE E'\n=== ТЕСТ 4: Триггер суммы заказа ===';
    -- Берём существующий заказ
    SELECT id_order INTO v_order_id FROM Orders WHERE order_number = 1001 LIMIT 1;
    SELECT total_amount INTO v_total_before FROM Orders WHERE id_order = v_order_id;
    RAISE NOTICE 'Сумма заказа №1001 до изменений: %', v_total_before;
    
    -- Получаем ID продукта "Стул офисный"
    SELECT id_product INTO v_product_id FROM Products WHERE name = 'Стул офисный' LIMIT 1;
    
    -- Добавляем новую позицию
    INSERT INTO Order_Items (id_order, id_product, quantity, price)
    VALUES (v_order_id, v_product_id, 3, 2500.00);
    
    SELECT total_amount INTO v_total_after FROM Orders WHERE id_order = v_order_id;
    RAISE NOTICE 'Сумма заказа после добавления 3 стульев: % (ожидается: % + 3*2500 = %)', 
        v_total_after, v_total_before, v_total_before + 7500;
    
    -- Изменяем количество в позиции
    UPDATE Order_Items SET quantity = 5 WHERE id_order = v_order_id AND id_product = v_product_id;
    SELECT total_amount INTO v_total_after FROM Orders WHERE id_order = v_order_id;
    RAISE NOTICE 'После изменения количества стульев с 3 на 5: % (ожидается: % + 2*2500 = %)', 
        v_total_after, v_total_before, v_total_before + 5000;
    
    -- Удаляем позицию
    DELETE FROM Order_Items WHERE id_order = v_order_id AND id_product = v_product_id;
    SELECT total_amount INTO v_total_after FROM Orders WHERE id_order = v_order_id;
    RAISE NOTICE 'После удаления стульев: % (должно вернуться к исходному %)', v_total_after, v_total_before;
END $$;

-- ============================================================
-- ТЕСТ 5: Расширенный триггер CalculateOrderWithCost (если используется)
-- ============================================================
DO $$
BEGIN
    RAISE NOTICE E'\n=== ТЕСТ 5: Расширенный триггер (если активен) ===';
    -- Проверяем, существует ли триггер
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_order_item_calc') THEN
        RAISE NOTICE 'Триггер trg_order_item_calc активен, проверяем автоматическое добавление в Cost_Calculation';
        -- Создаём новый продукт и заказ для проверки
        DECLARE
            v_new_product_id INTEGER;
            v_new_material_id INTEGER;
            v_new_order_id INTEGER;
            v_zakazchik_id INTEGER;
        BEGIN
            INSERT INTO Products (name, unit, price) VALUES ('Тестовый продукт', 'шт', 1000) RETURNING id_product INTO v_new_product_id;
            INSERT INTO Materials (name, unit, code) VALUES ('Тестовый материал', 'кг', 'TEST') RETURNING id_material INTO v_new_material_id;
            INSERT INTO Specifications (id_product, id_material, quantity) VALUES (v_new_product_id, v_new_material_id, 1.5);
            SELECT id_zakazchik INTO v_zakazchik_id FROM Zakazchiki LIMIT 1;
            INSERT INTO Orders (order_number, order_date, id_zakazchik) VALUES (9999, CURRENT_DATE, v_zakazchik_id) RETURNING id_order INTO v_new_order_id;
            INSERT INTO Order_Items (id_order, id_product, quantity, price) VALUES (v_new_order_id, v_new_product_id, 2, 1000);
            
            -- Проверяем, появилась ли запись в Cost_Calculation
            IF EXISTS (SELECT 1 FROM Cost_Calculation WHERE id_product = v_new_product_id) THEN
                RAISE NOTICE '✅ Запись в Cost_Calculation автоматически создана.';
            ELSE
                RAISE NOTICE '❌ Запись в Cost_Calculation не создана.';
            END IF;
        END;
    ELSE
        RAISE NOTICE 'Триггер trg_order_item_calc не активен, тест пропущен.';
    END IF;
END $$;

-- ============================================================
-- ТЕСТ 6: Комплексная проверка целостности данных
-- ============================================================
DO $$
DECLARE
    v_orders_count INTEGER;
    v_items_count INTEGER;
    v_sum_orders NUMERIC;
    v_sum_items NUMERIC;
    v_orphan_count INTEGER;
BEGIN
    RAISE NOTICE E'\n=== ТЕСТ 6: Проверка целостности ===';
    SELECT COUNT(*) INTO v_orders_count FROM Orders;
    SELECT COUNT(*) INTO v_items_count FROM Order_Items;
    SELECT COALESCE(SUM(total_amount),0) INTO v_sum_orders FROM Orders;
    SELECT COALESCE(SUM(amount),0) INTO v_sum_items FROM Order_Items;
    
    RAISE NOTICE 'Всего заказов: %, позиций: %', v_orders_count, v_items_count;
    RAISE NOTICE 'Сумма всех заказов (из Orders): %', v_sum_orders;
    RAISE NOTICE 'Сумма всех позиций (из Order_Items): %', v_sum_items;
    
    IF v_sum_orders = v_sum_items THEN
        RAISE NOTICE '✅ Консистентность данных соблюдена: суммы совпадают.';
    ELSE
        RAISE NOTICE '❌ Ошибка: суммы не совпадают! Разница: %', v_sum_orders - v_sum_items;
    END IF;
    
    -- Проверка внешних ключей Order_Items -> Products
    SELECT COUNT(*) INTO v_orphan_count 
    FROM Order_Items oi 
    LEFT JOIN Products p ON oi.id_product = p.id_product 
    WHERE p.id_product IS NULL;
    
    IF v_orphan_count = 0 THEN
        RAISE NOTICE '✅ Все позиции заказов ссылаются на существующие продукты.';
    ELSE
        RAISE NOTICE '❌ Есть % позиций заказов с несуществующими продуктами.', v_orphan_count;
    END IF;
END $$;

-- ============================================================
-- ОЧИСТКА ТЕСТОВЫХ ДАННЫХ (опционально)
-- ============================================================
-- Если вы хотите откатить изменения (запустив весь скрипт в транзакции), используйте:
-- ROLLBACK;
-- Или вручную очистить:
-- TRUNCATE Order_Items, Orders, Cost_Calculation, Specifications, Prices, Products, Materials, Zakazchiki CASCADE;