-- ============================================================
-- ПРОЦЕДУРА: GetOrdersStatisticsTable
-- Назначение: возвращает результат в виде таблицы (для использования в приложениях)
-- ============================================================

CREATE OR REPLACE FUNCTION GetOrdersStatisticsTable(
    p_date_from DATE,
    p_date_to DATE,
    p_zakazchik_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    zakazchik_name VARCHAR(255),
    zakazchik_inn VARCHAR(12),
    total_orders BIGINT,
    total_quantity NUMERIC(15,2),
    total_amount NUMERIC(15,2)
)
LANGUAGE sql
AS $$
    SELECT 
        z.name AS zakazchik_name,
        z.inn AS zakazchik_inn,
        COUNT(DISTINCT o.id_order)::BIGINT AS total_orders,
        COALESCE(SUM(oi.quantity), 0) AS total_quantity,
        COALESCE(SUM(oi.amount), 0) AS total_amount
    FROM Zakazchiki z
    LEFT JOIN Orders o ON z.id_zakazchik = o.id_zakazchik 
        AND o.order_date BETWEEN p_date_from AND p_date_to
    LEFT JOIN Order_Items oi ON o.id_order = oi.id_order
    WHERE (p_zakazchik_id IS NULL OR z.id_zakazchik = p_zakazchik_id)
    GROUP BY z.name, z.inn
    ORDER BY total_amount DESC;
$$;

-- Пример использования:
-- SELECT * FROM GetOrdersStatisticsTable('2024-01-01', '2024-12-31');
-- SELECT * FROM GetOrdersStatisticsTable('2024-01-01', '2024-12-31', 1);