-- ============================================================
-- ФУНКЦИЯ: CalculateProductCost
-- Назначение: рассчитывает себестоимость продукции на основе
--             норм расхода материалов и их текущей стоимости
-- ============================================================

CREATE OR REPLACE FUNCTION CalculateProductCost(
    p_id_product INTEGER,
    p_quantity NUMERIC(10,2) DEFAULT 1
)
RETURNS NUMERIC(15,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_cost NUMERIC(15,2) := 0;
    v_mat_quantity NUMERIC(10,4);
    v_mat_price NUMERIC(10,2);
    v_material_cost NUMERIC(12,2);
    v_rec RECORD;
BEGIN
    -- Для каждого материала в спецификации продукта
    FOR v_rec IN
        SELECT 
            s.id_material,
            s.quantity as norm_quantity
        FROM Specifications s
        WHERE s.id_product = p_id_product
    LOOP
        -- Берем актуальную цену материала (из таблицы Cost_Calculation или последнюю)
        SELECT mat_price INTO v_mat_price
        FROM Cost_Calculation
        WHERE id_product = p_id_product 
          AND id_material = v_rec.id_material
        ORDER BY id_cost DESC
        LIMIT 1;
        
        -- Если цены нет в Cost_Calculation, используем 0
        IF v_mat_price IS NULL THEN
            v_mat_price := 0;
            RAISE NOTICE 'Для материала % нет цены в Cost_Calculation', v_rec.id_material;
        END IF;
        
        -- Стоимость материала для нормы расхода
        v_material_cost := v_rec.norm_quantity * v_mat_price;
        v_total_cost := v_total_cost + v_material_cost;
    END LOOP;
    
    -- Умножаем на количество продукции
    RETURN v_total_cost * p_quantity;
END;
$$;