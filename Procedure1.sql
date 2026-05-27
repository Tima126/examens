-- ============================================================
-- ПРОЦЕДУРА: GetOrdersStatistics
-- Назначение: выводит общее количество заказов, количество продукции,
--             общую сумму заказов и данные заказчика за период
-- ============================================================

CREATE OR REPLACE PROCEDURE GetOrdersStatistics(
    p_date_from DATE,
    p_date_to DATE,
    p_zakazchik_id INTEGER DEFAULT NULL  -- если NULL, то по всем заказчикам
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_orders INTEGER;
    v_total_quantity NUMERIC(15,2);
    v_total_amount NUMERIC(15,2);
    v_zakazchik_name VARCHAR(255);
    v_zakazchik_inn VARCHAR(12);
BEGIN
    -- Если ID заказчика не указан, выводим сводку по всем
    IF p_zakazchik_id IS NULL THEN
        -- Статистика по всем заказчикам
        SELECT 
            COUNT(DISTINCT o.id_order),
            COALESCE(SUM(oi.quantity), 0),
            COALESCE(SUM(oi.amount), 0)
        INTO 
            v_total_orders,
            v_total_quantity,
            v_total_amount
        FROM Orders o
        LEFT JOIN Order_Items oi ON o.id_order = oi.id_order
        WHERE o.order_date BETWEEN p_date_from AND p_date_to;
        
        -- Вывод результата
        RAISE NOTICE '==========================================';
        RAISE NOTICE 'СТАТИСТИКА ПО ЗАКАЗАМ ЗА ПЕРИОД: % - %', p_date_from, p_date_to;
        RAISE NOTICE '==========================================';
        RAISE NOTICE 'Общее количество заказов: %', v_total_orders;
        RAISE NOTICE 'Общее количество продукции (ед.): %', v_total_quantity;
        RAISE NOTICE 'Общая сумма заказов: % руб.', v_total_amount;
        RAISE NOTICE '==========================================';
        
    ELSE
        -- Статистика по конкретному заказчику
        SELECT 
            z.name,
            z.inn,
            COUNT(DISTINCT o.id_order),
            COALESCE(SUM(oi.quantity), 0),
            COALESCE(SUM(oi.amount), 0)
        INTO 
            v_zakazchik_name,
            v_zakazchik_inn,
            v_total_orders,
            v_total_quantity,
            v_total_amount
        FROM Zakazchiki z
        LEFT JOIN Orders o ON z.id_zakazchik = o.id_zakazchik 
            AND o.order_date BETWEEN p_date_from AND p_date_to
        LEFT JOIN Order_Items oi ON o.id_order = oi.id_order
        WHERE z.id_zakazchik = p_zakazchik_id
        GROUP BY z.name, z.inn;
        
        -- Вывод результата
        RAISE NOTICE '==========================================';
        RAISE NOTICE 'СТАТИСТИКА ПО ЗАКАЗЧИКУ ЗА ПЕРИОД: % - %', p_date_from, p_date_to;
        RAISE NOTICE '==========================================';
        RAISE NOTICE 'Заказчик: % (ИНН: %)', v_zakazchik_name, v_zakazchik_inn;
        RAISE NOTICE 'Количество заказов: %', v_total_orders;
        RAISE NOTICE 'Количество продукции (ед.): %', v_total_quantity;
        RAISE NOTICE 'Общая сумма заказов: % руб.', v_total_amount;
        RAISE NOTICE '==========================================';
    END IF;
END;
$$;

-- Примеры вызова процедуры:
-- CALL GetOrdersStatistics('2024-01-01', '2024-12-31');  -- по всем
-- CALL GetOrdersStatistics('2024-01-01', '2024-12-31', 1);  -- по заказчику с id=1