-- ============================================================
-- СОЗДАНИЕ ТАБЛИЦ БАЗЫ ДАННЫХ
-- ============================================================

-- 1. Zakazchiki (таблица контрагентов - покупатели и продавцы)
CREATE TABLE IF NOT EXISTS Zakazchiki (
    id_zakazchik SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    inn VARCHAR(12),
    address VARCHAR(255),
    phone VARCHAR(20),
    is_salesman BOOLEAN DEFAULT FALSE,
    is_buyer BOOLEAN DEFAULT FALSE
);

-- 2. Products (таблица готовой продукции)
CREATE TABLE IF NOT EXISTS Products (
    id_product SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    price NUMERIC(10,2)
);

-- 3. Materials (таблица сырья и материалов)
CREATE TABLE IF NOT EXISTS Materials (
    id_material SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    code VARCHAR(50)
);

-- 4. Specifications (спецификации - какие материалы нужны для продуктов)
CREATE TABLE IF NOT EXISTS Specifications (
    id_spec SERIAL PRIMARY KEY,
    id_product INTEGER NOT NULL REFERENCES Products(id_product) ON DELETE CASCADE,
    id_material INTEGER NOT NULL REFERENCES Materials(id_material) ON DELETE RESTRICT,
    quantity NUMERIC(10,4) NOT NULL CHECK (quantity > 0),
    UNIQUE(id_product, id_material)
);

-- 5. Prices (история цен на продукты)
CREATE TABLE IF NOT EXISTS Prices (
    id_price SERIAL PRIMARY KEY,
    id_product INTEGER NOT NULL REFERENCES Products(id_product) ON DELETE CASCADE,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    date_from DATE NOT NULL,
    date_to DATE,
    CHECK (date_to IS NULL OR date_to >= date_from)
);

-- 6. Orders (заказы от покупателей)
CREATE TABLE IF NOT EXISTS Orders (
    id_order SERIAL PRIMARY KEY,
    order_number INTEGER NOT NULL UNIQUE,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    id_zakazchik INTEGER NOT NULL REFERENCES Zakazchiki(id_zakazchik) ON DELETE RESTRICT,
    total_amount NUMERIC(12,2) DEFAULT 0
);

-- 7. Order_Items (позиции заказа)
CREATE TABLE IF NOT EXISTS Order_Items (
    id_order_item SERIAL PRIMARY KEY,
    id_order INTEGER NOT NULL REFERENCES Orders(id_order) ON DELETE CASCADE,
    id_product INTEGER NOT NULL REFERENCES Products(id_product) ON DELETE RESTRICT,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    amount NUMERIC(12,2) GENERATED ALWAYS AS (quantity * price) STORED
);

-- 8. Production (производство готовой продукции)
CREATE TABLE IF NOT EXISTS Production (
    id_production SERIAL PRIMARY KEY,
    prod_number INTEGER NOT NULL UNIQUE,
    prod_date DATE NOT NULL DEFAULT CURRENT_DATE,
    id_product INTEGER NOT NULL REFERENCES Products(id_product) ON DELETE RESTRICT,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    unit VARCHAR(20) NOT NULL
);

-- 9. Production_Materials (расход материалов на производство)
CREATE TABLE IF NOT EXISTS Production_Materials (
    id_mat_usage SERIAL PRIMARY KEY,
    id_production INTEGER NOT NULL REFERENCES Production(id_production) ON DELETE CASCADE,
    id_material INTEGER NOT NULL REFERENCES Materials(id_material) ON DELETE RESTRICT,
    quantity NUMERIC(10,4) NOT NULL CHECK (quantity > 0),
    unit VARCHAR(20) NOT NULL
);

-- 10. Cost_Calculation (калькуляция себестоимости)
CREATE TABLE IF NOT EXISTS Cost_Calculation (
    id_cost SERIAL PRIMARY KEY,
    id_product INTEGER NOT NULL REFERENCES Products(id_product) ON DELETE CASCADE,
    id_material INTEGER NOT NULL REFERENCES Materials(id_material) ON DELETE RESTRICT,
    mat_quantity NUMERIC(10,4) NOT NULL CHECK (mat_quantity > 0),
    mat_price NUMERIC(10,2) NOT NULL CHECK (mat_price >= 0),
    mat_amount NUMERIC(12,2) GENERATED ALWAYS AS (mat_quantity * mat_price) STORED,
    total_cost NUMERIC(12,2)
);

-- ============================================================
-- СОЗДАНИЕ ИНДЕКСОВ ДЛЯ ОПТИМИЗАЦИИ ЗАПРОСОВ
-- ============================================================

-- Индексы для внешних ключей
CREATE INDEX idx_specifications_product ON Specifications(id_product);
CREATE INDEX idx_specifications_material ON Specifications(id_material);
CREATE INDEX idx_prices_product ON Prices(id_product);
CREATE INDEX idx_orders_zakazchik ON Orders(id_zakazchik);
CREATE INDEX idx_orders_date ON Orders(order_date);
CREATE INDEX idx_order_items_order ON Order_Items(id_order);
CREATE INDEX idx_order_items_product ON Order_Items(id_product);
CREATE INDEX idx_production_product ON Production(id_product);
CREATE INDEX idx_production_date ON Production(prod_date);
CREATE INDEX idx_production_materials_production ON Production_Materials(id_production);
CREATE INDEX idx_production_materials_material ON Production_Materials(id_material);
CREATE INDEX idx_cost_calculation_product ON Cost_Calculation(id_product);
CREATE INDEX idx_cost_calculation_material ON Cost_Calculation(id_material);

-- Индексы для поиска по текстовым полям
CREATE INDEX idx_zakazchiki_name ON Zakazchiki(name);
CREATE INDEX idx_zakazchiki_inn ON Zakazchiki(inn);
CREATE INDEX idx_products_name ON Products(name);
CREATE INDEX idx_materials_name ON Materials(name);
CREATE INDEX idx_materials_code ON Materials(code);

-- ============================================================
-- КОММЕНТАРИИ К ТАБЛИЦАМ (документация)
-- ============================================================

COMMENT ON TABLE Zakazchiki IS 'Контрагенты (покупатели и продавцы)';
COMMENT ON TABLE Products IS 'Готовая продукция';
COMMENT ON TABLE Materials IS 'Сырьё и материалы';
COMMENT ON TABLE Specifications IS 'Спецификации (нормы расхода материалов на продукт)';
COMMENT ON TABLE Prices IS 'История цен на продукцию';
COMMENT ON TABLE Orders IS 'Заказы от покупателей';
COMMENT ON TABLE Order_Items IS 'Позиции заказа';
COMMENT ON TABLE Production IS 'Производство готовой продукции';
COMMENT ON TABLE Production_Materials IS 'Фактический расход материалов на производство';
COMMENT ON TABLE Cost_Calculation IS 'Калькуляция себестоимости продукции';

-- ============================================================
-- ПРОВЕРКА СОЗДАНИЯ ТАБЛИЦ
-- ============================================================

SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;