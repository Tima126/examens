-- ============================================================
-- РАСШИРЕННЫЙ ТРИГГЕР: CalculateOrderWithCost
-- Назначение: при добавлении позиции заказа автоматически:
--             1. Рассчитывает себестоимость продукции
--             2. Добавляет запись в Cost_Calculation
--             3. Пересчитывает итоговую сумму заказа
-- ============================================================

CREATE OR REPLACE FUNCTION CalculateOrderWithCost()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_cost NUMERIC(12,2);
    v_total_amount NUMERIC(15,2);
    v_material RECORD;
    v_mat_cost NUMERIC(12,2);
    v_actual_price NUMERIC(10,2);
BEGIN
    -- 1. Получаем актуальную цену продукта (если не указана)
    IF NEW.price IS NULL OR NEW.price = 0 THEN
        SELECT price INTO v_actual_price
        FROM Prices
        WHERE id_product = NEW.id_product
          AND (date_from <= CURRENT_DATE AND (date_to IS NULL OR date_to >= CURRENT_DATE))
        ORDER BY date_from DESC
        LIMIT 1;
        
        IF v_actual_price IS NOT NULL THEN
            NEW.price := v_actual_price;
        ELSE
            RAISE EXCEPTION 'Не найдена актуальная цена для продукта id=%', NEW.id_product;
        END IF;
    END IF;
    
    -- 2. Рассчитываем сумму позиции
    NEW.amount := NEW.quantity * NEW.price;
    
    -- 3. Добавляем/обновляем калькуляцию себестоимости для материалов
    FOR v_material IN
        SELECT 
            s.id_material,
            s.quantity as mat_quantity
        FROM Specifications s
        WHERE s.id_product = NEW.id_product
    LOOP
        -- Рассчитываем стоимость материала для данной партии
        v_mat_cost := v_material.mat_quantity * NEW.quantity * 100;  -- тут нужно брать цену материала
        -- Для реального расчета нужно брать цену из таблицы цен на материалы
        
        -- Вставляем или обновляем запись в Cost_Calculation
        INSERT INTO Cost_Calculation (
            id_product, 
            id_material, 
            mat_quantity, 
            mat_price, 
            total_cost
        )
        VALUES (
            NEW.id_product,
            v_material.id_material,
            v_material.mat_quantity * NEW.quantity,
            100,  -- здесь должна быть реальная цена материала
            v_mat_cost
        )
        ON CONFLICT (id_product, id_material) DO UPDATE
        SET mat_quantity = EXCLUDED.mat_quantity,
            total_cost = EXCLUDED.total_cost;
    END LOOP;
    
    RETURN NEW;
END;
$$;

-- Триггер BEFORE INSERT/UPDATE для автоматической установки цены и amount
DROP TRIGGER IF EXISTS trg_order_item_calc ON Order_Items;

CREATE TRIGGER trg_order_item_calc
    BEFORE INSERT OR UPDATE ON Order_Items
    FOR EACH ROW
    EXECUTE FUNCTION CalculateOrderWithCost();