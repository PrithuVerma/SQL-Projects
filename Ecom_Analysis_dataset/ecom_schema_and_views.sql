-- =============================================================================
-- E-commerce Analysis Dataset - SQL Schema & Analytical Views
-- =============================================================================
-- Purpose: Database schema and visualization-ready views for 6 CSV tables
-- Tables: customers, orders, order_items, products, categories, returns
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SECTION 1: DROP EXISTING OBJECTS (for clean setup)
-- -----------------------------------------------------------------------------

DROP VIEW IF EXISTS v_sales_dashboard;
DROP VIEW IF EXISTS v_customer_order_summary;
DROP VIEW IF EXISTS v_product_performance;
DROP VIEW IF EXISTS v_category_analytics;
DROP VIEW IF EXISTS v_returns_analysis;
DROP VIEW IF EXISTS v_order_details_full;

DROP TABLE IF EXISTS returns;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;

-- -----------------------------------------------------------------------------
-- SECTION 2: TABLE DEFINITIONS
-- -----------------------------------------------------------------------------

-- Customers: Customer master data
CREATE TABLE customers (
    customer_id    INTEGER PRIMARY KEY,
    name           TEXT NOT NULL,
    email          TEXT NOT NULL,
    signup_date    DATE NOT NULL,
    city           TEXT,
    state          TEXT
);

-- Categories: Product category lookup
CREATE TABLE categories (
    category_id    INTEGER PRIMARY KEY,
    category_name  TEXT NOT NULL
);

-- Products: Product master with category reference
CREATE TABLE products (
    product_id     INTEGER PRIMARY KEY,
    product_name   TEXT NOT NULL,
    category_id    INTEGER NOT NULL,
    price          REAL NOT NULL,
    cost_price     REAL NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Orders: Order header with customer reference
CREATE TABLE orders (
    order_id       INTEGER PRIMARY KEY,
    customer_id    INTEGER NOT NULL,
    order_status   TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Order Items: Order line items (links orders to products)
CREATE TABLE order_items (
    order_item_id  INTEGER PRIMARY KEY,
    order_id       INTEGER NOT NULL,
    product_id     INTEGER NOT NULL,
    quantity       INTEGER NOT NULL,
    unit_price     REAL NOT NULL,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Returns: Returned order items
CREATE TABLE returns (
    return_id      INTEGER PRIMARY KEY,
    order_item_id  INTEGER NOT NULL,
    return_date    DATE NOT NULL,
    refund_amount  REAL NOT NULL,
    FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id)
);

-- -----------------------------------------------------------------------------
-- SECTION 3: LOAD DATA (SQLite - run from sqlite3 CLI)
-- -----------------------------------------------------------------------------
-- Execute these in sqlite3 after creating tables:
--
-- .mode csv
-- .import --skip 1 customers.csv customers
-- .import --skip 1 categories.csv categories
-- .import --skip 1 products.csv products
-- .import --skip 1 orders.csv orders
-- .import --skip 1 order_items.csv order_items
-- .import --skip 1 returns.csv returns
--
-- Or use Python/pandas: df.to_sql('customers', conn, if_exists='append')
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- SECTION 4: ANALYTICAL VIEWS (for data visualization)
-- -----------------------------------------------------------------------------

-- View 1: Full order details - denormalized for dashboards
-- Use for: Order-level analysis, customer-product links, revenue by line
CREATE VIEW v_order_details_full AS
SELECT 
    oi.order_item_id,
    oi.order_id,
    o.order_status,
    o.payment_method,
    o.customer_id,
    c.name AS customer_name,
    c.email,
    c.city,
    c.state,
    c.signup_date,
    oi.product_id,
    p.product_name,
    p.category_id,
    cat.category_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS line_total,
    (oi.quantity * (oi.unit_price - p.cost_price)) AS line_profit
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id;

-- View 2: Sales dashboard metrics - aggregated for KPIs
-- Use for: Revenue, quantity, profit by category, status, payment
CREATE VIEW v_sales_dashboard AS
SELECT 
    order_status,
    payment_method,
    category_name,
    state,
    COUNT(DISTINCT order_id) AS order_count,
    COUNT(*) AS line_count,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(line_total), 2) AS total_revenue,
    ROUND(SUM(line_profit), 2) AS total_profit,
    ROUND(AVG(line_total), 2) AS avg_order_value
FROM v_order_details_full
GROUP BY order_status, payment_method, category_name, state;

-- View 3: Customer order summary - for RFM-style analysis
-- Use for: Customer cohorts, top customers, order frequency
CREATE VIEW v_customer_order_summary AS
SELECT 
    c.customer_id,
    c.name,
    c.city,
    c.state,
    c.signup_date,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.quantity) AS total_items,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_spent,
    ROUND(AVG(oi.quantity * oi.unit_price), 2) AS avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.name, c.city, c.state, c.signup_date;

-- View 4: Product performance - for product/category analytics
-- Use for: Best sellers, category comparison, margin analysis
CREATE VIEW v_product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    cat.category_id,
    cat.category_name,
    p.price,
    p.cost_price,
    ROUND(p.price - p.cost_price, 2) AS unit_margin,
    COALESCE(SUM(oi.quantity), 0) AS units_sold,
    ROUND(COALESCE(SUM(oi.quantity * oi.unit_price), 0), 2) AS revenue,
    ROUND(COALESCE(SUM(oi.quantity * (oi.unit_price - p.cost_price)), 0), 2) AS profit
FROM products p
JOIN categories cat ON p.category_id = cat.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.order_status != 'Canceled'
GROUP BY p.product_id, p.product_name, cat.category_id, cat.category_name, p.price, p.cost_price;

-- View 5: Category analytics - for category-level visualizations
-- Use for: Category comparison, Pareto charts
CREATE VIEW v_category_analytics AS
SELECT 
    cat.category_id,
    cat.category_name,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(DISTINCT oi.order_id) AS order_count,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price - p.cost_price)), 2) AS profit
FROM categories cat
JOIN products p ON cat.category_id = p.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.order_status != 'Canceled'
GROUP BY cat.category_id, cat.category_name;

-- View 6: Returns analysis - for return rate and refund insights
-- Use for: Return trends, product return rates, refund amounts
CREATE VIEW v_returns_analysis AS
SELECT 
    r.return_id,
    r.order_item_id,
    r.return_date,
    r.refund_amount,
    oi.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    p.product_name,
    cat.category_name
FROM returns r
JOIN order_items oi ON r.order_item_id = oi.order_item_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id;

-- -----------------------------------------------------------------------------
-- SECTION 5: EXAMPLE QUERIES (for common visualizations)
-- -----------------------------------------------------------------------------

-- Revenue by category (bar chart)
-- SELECT category_name, SUM(revenue) AS revenue FROM v_product_performance GROUP BY category_name;

-- Orders by status (pie chart)
-- SELECT order_status, COUNT(*) FROM v_order_details_full GROUP BY order_status;

-- Top 10 products by revenue
-- SELECT product_name, revenue FROM v_product_performance ORDER BY revenue DESC LIMIT 10;

-- Revenue by state (choropleth / bar)
-- SELECT state, SUM(total_spent) AS revenue FROM v_customer_order_summary GROUP BY state;

-- Payment method distribution
-- SELECT payment_method, COUNT(DISTINCT order_id) FROM v_order_details_full GROUP BY payment_method;
