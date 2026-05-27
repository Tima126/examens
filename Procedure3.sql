-- ============================================================
-- ФУНКЦИЯ ТРИГГЕРА: CalculateOrderTotal
-- Назначение: автоматически пересчитывает общую сумму заказа
--             при добавлении/изменении/удалении позиций заказа
-- ============================================================

CREATE OR REPLACE FUNCTION CalculateOrderTotal()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_amount NUMERIC(15,2);
    v_order_id INTEGER;
BEGIN
    -- Определяем ID заказа в зависимости от операции
    IF TG_OP = 'DELETE' THEN
        v_order_id := OLD.id_order;
    ELSE
        v_order_id := NEW.id_order;
    END IF;
    
    -- Пересчитываем общую сумму заказа
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_amount
    FROM Order_Items
    WHERE id_order = v_order_id;
    
    -- Обновляем total_amount в таблице Orders
    UPDATE Orders 
    SET total_amount = v_total_amount
    WHERE id_order = v_order_id;
    
    -- Для INSERT/UPDATE возвращаем NEW, для DELETE возвращаем OLD
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- Создаем триггер на таблицу Order_Items
DROP TRIGGER IF EXISTS trg_calculate_order_total ON Order_Items;

CREATE TRIGGER trg_calculate_order_total
    AFTER INSERT OR UPDATE OR DELETE ON Order_Items
    FOR EACH ROW
    EXECUTE FUNCTION CalculateOrderTotal();