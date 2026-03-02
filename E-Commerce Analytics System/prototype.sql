USE ecom;

/* =========================================================
   1. CONSTRAINT HARDENING
   ========================================================= */

ALTER TABLE customers
MODIFY email VARCHAR(255) NOT NULL,
ADD CONSTRAINT unique_email UNIQUE (email);

ALTER TABLE orders
MODIFY order_date DATETIME NOT NULL,
MODIFY total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0);

ALTER TABLE products
MODIFY price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
MODIFY stock_quantity INT NOT NULL CHECK (stock_quantity >= 0);

/* =========================================================
   2. PERFORMANCE INDEXING
   ========================================================= */

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_orderitems_product ON order_items(product_id);

/* Composite index for analytics */
CREATE INDEX idx_orders_customer_date 
ON orders(customer_id, order_date);

/* =========================================================
   3. DERIVED DATA COLUMN
   ========================================================= */

ALTER TABLE order_items
ADD COLUMN line_total DECIMAL(10,2) 
GENERATED ALWAYS AS (quantity * price) STORED;

/* =========================================================
   4. ANALYTICS VIEWS
   ========================================================= */

/* Top Customers by Revenue */
CREATE OR REPLACE VIEW top_customers AS
SELECT 
    c.customer_id,
    c.name,
    SUM(o.total_amount) AS lifetime_value,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY lifetime_value DESC;

/* Monthly Revenue */
CREATE OR REPLACE VIEW monthly_revenue AS
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(total_amount) AS revenue,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY month
ORDER BY month;

/* Product Performance */
CREATE OR REPLACE VIEW product_sales AS
SELECT 
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.price) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;

/* =========================================================
   5. STORED PROCEDURES
   ========================================================= */

DELIMITER //

CREATE PROCEDURE GetCustomerLifetimeValue(IN cust_id INT)
BEGIN
    SELECT 
        c.customer_id,
        c.name,
        SUM(o.total_amount) AS lifetime_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE c.customer_id = cust_id
    GROUP BY c.customer_id, c.name;
END //

CREATE PROCEDURE GetRevenueBetweenDates(
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    SELECT 
        SUM(total_amount) AS revenue,
        COUNT(order_id) AS total_orders
    FROM orders
    WHERE order_date BETWEEN start_date AND end_date;
END //

DELIMITER ;

/* =========================================================
   6. TRIGGER – AUTO UPDATE STOCK
   ========================================================= */

DELIMITER //

CREATE TRIGGER reduce_stock_after_order
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
END //

DELIMITER ;
