# 🏦 Banking SQL Project

A structured SQL project built on a multi-table banking database, demonstrating real-world query writing across increasing levels of complexity. Designed to showcase practical SQL skills relevant to Data Analyst and SQL Developer roles.

---

## 📁 Project Structure

```
Banking/
├── Bank_Analysis_1.sql     # Customer & account analysis queries
├── Loan_analysis.sql       # Loan exposure and risk categorization
├── Final_Report.sql        # Complete customer 360 view across all tables
└── README.md
```

---

## 🗄️ Database Schema

The project uses a normalized banking database with 5 interconnected tables:

<img width="587" height="453" alt="Screenshot 2026-03-07 at 4 51 25 PM" src="https://github.com/user-attachments/assets/33cf3f24-b897-470e-ba6a-2ce45c1863ec" />


| Table | Description |
|-------|-------------|
| `customers` | Customer profiles — name, city, date of birth, join date |
| `accounts` | Bank accounts linked to customers and branches |
| `branches` | Branch details — name and city |
| `loans` | Loan records with amount, interest rate, and status |
| `transactions` | Individual debit/credit transactions per account |

---

## 📊 Analyses Performed

### 1. Customer Account Summary
Joins `customers` and `accounts` to show total accounts and combined balance per customer.

**Concepts:** LEFT JOIN, GROUP BY, SUM, COUNT, ROUND

```sql
SELECT c.customer_id, c.name,
       COUNT(a.account_id) AS total_accounts,
       ROUND(SUM(a.balance), 2) AS total_balance
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.name;
```

**Business meaning:** Identifies high-value customers by total deposits held across all their accounts.

---

### 2. Branch-wise Account Distribution
Shows how accounts are distributed across branches, including branches with zero accounts.

**Concepts:** LEFT JOIN, COUNT, GROUP BY, ORDER BY

```sql
SELECT b.branch_name, b.city,
       COUNT(a.account_id) AS total_accounts
FROM branches b
LEFT JOIN accounts a ON b.branch_id = a.branch_id
GROUP BY b.branch_name, b.city
ORDER BY total_accounts DESC;
```

**Business meaning:** Helps identify underperforming or overloaded branches for resource planning.

---

### 3. Top 10 Customers by Total Loan Exposure
Ranks customers by total loan amount taken across all their loans.

**Concepts:** LEFT JOIN, SUM, GROUP BY, ORDER BY, LIMIT

```sql
SELECT c.name, c.customer_id,
       ROUND(SUM(l.loan_amount), 2) AS total_loan_exposure
FROM customers c
LEFT JOIN loans l ON c.customer_id = l.customer_id
GROUP BY c.name, c.customer_id
ORDER BY total_loan_exposure DESC
LIMIT 10;
```

**Business meaning:** Flags high-exposure customers for credit risk monitoring.

---

### 4. Customers with Multiple Active Loans
Identifies customers currently holding more than one active loan simultaneously.

**Concepts:** LEFT JOIN, WHERE, GROUP BY, HAVING, COUNT

```sql
SELECT c.name, c.customer_id,
       COUNT(l.loan_id) AS active_loan_count
FROM customers c
LEFT JOIN loans l ON c.customer_id = l.customer_id
WHERE l.loan_status = 'Active'
GROUP BY c.name, c.customer_id
HAVING COUNT(l.loan_id) > 1;
```

**Business meaning:** Highlights customers with high debt burden — a key risk indicator for banks.

---

### 5. Transaction Summary by Account Type
Summarizes total transaction volume and value grouped by account type, using RIGHT JOIN to include accounts with zero transactions (dormant accounts).

**Concepts:** RIGHT JOIN, SUM, COUNT, GROUP BY, ROUND

```sql
SELECT a.account_type,
       t.transaction_type,
       COUNT(t.transaction_id) AS total_transactions,
       ROUND(SUM(t.amount), 2) AS total_amount
FROM transactions t
RIGHT JOIN accounts a ON t.account_id = a.account_id
GROUP BY a.account_type, t.transaction_type;
```

**Business meaning:** Reveals dormant accounts (NULL rows) and compares debit vs credit activity across account types.

---

### 6. Monthly Transaction Trends
Breaks down transaction volume and value by month and year to identify seasonal patterns.

**Concepts:** MONTH(), YEAR(), GROUP BY, ORDER BY, COUNT, SUM

```sql
SELECT YEAR(transaction_date) AS years,
       MONTH(transaction_date) AS months,
       COUNT(transaction_id) AS total_transactions,
       ROUND(SUM(amount), 2) AS total_amount
FROM transactions
GROUP BY YEAR(transaction_date), MONTH(transaction_date)
ORDER BY years, months;
```

**Business meaning:** Helps identify high-activity periods for staffing, fraud detection, and financial planning.

---

### 7. Customer 360 View (All 5 Tables)
A comprehensive view joining all tables to give a complete picture of each customer — their accounts, branch, loans, and transaction activity.

**Concepts:** 4x LEFT JOIN, GROUP BY, COUNT DISTINCT, SUM, CREATE VIEW

```sql
CREATE VIEW customer_360 AS
SELECT
    c.customer_id,
    c.name,
    c.city,
    COUNT(DISTINCT a.account_id)      AS total_accounts,
    ROUND(SUM(a.balance), 2)          AS total_balance,
    b.branch_name,
    COUNT(DISTINCT l.loan_id)         AS total_loans,
    ROUND(SUM(l.loan_amount), 2)      AS total_loan_exposure,
    COUNT(DISTINCT t.transaction_id)  AS total_transactions
FROM customers c
LEFT JOIN accounts a      ON c.customer_id = a.customer_id
LEFT JOIN branches b      ON a.branch_id   = b.branch_id
LEFT JOIN loans l         ON c.customer_id = l.customer_id
LEFT JOIN transactions t  ON a.account_id  = t.account_id
GROUP BY c.customer_id, c.name, c.city, b.branch_name;
```

**Business meaning:** A single query that gives a bank relationship manager everything they need to know about a customer in one view.

---

## 🔧 Advanced SQL Features

### Views
Saved queries that behave like virtual tables — used to simplify repeated complex queries and restrict data access by role.

```sql
CREATE VIEW branch_account_distribution AS
SELECT b.branch_name, b.city, COUNT(a.account_id) AS total_accounts
FROM branches b
LEFT JOIN accounts a ON b.branch_id = a.branch_id
GROUP BY b.branch_name, b.city;

-- Query it anytime like a table
SELECT * FROM branch_account_distribution;
```

---

### Stored Functions
Custom reusable functions that extend SQL's built-in capabilities. Used here to classify loans into risk categories.

```sql
CREATE FUNCTION getRiskCategory(loan_amount DECIMAL(10,2))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    IF loan_amount < 100000 THEN
        RETURN 'Low Risk';
    ELSEIF loan_amount BETWEEN 100000 AND 1000000 THEN
        RETURN 'Medium Risk';
    ELSE
        RETURN 'High Risk';
    END IF;
END;

-- Use it like any built-in function
SELECT name, loan_amount, getRiskCategory(loan_amount) AS risk_category
FROM customers
INNER JOIN loans ON customers.customer_id = loans.customer_id;
```

---

### Triggers
Automatically executes logic when a table event occurs. Used here to prevent invalid loan data from entering the database.

```sql
CREATE TRIGGER validate_loan_amount
BEFORE INSERT ON loans
FOR EACH ROW
BEGIN
    IF NEW.loan_amount < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Loan amount cannot be negative';
    END IF;
END;
```

---

## 🧠 SQL Concepts Covered

| Concept | Used In |
|---------|---------|
| SELECT, WHERE, GROUP BY, HAVING | All queries |
| INNER, LEFT, RIGHT JOIN | Queries 1–7 |
| Multi-table JOIN (4 tables) | Customer 360 View |
| Aggregate functions (COUNT, SUM, AVG, MAX, MIN) | All queries |
| DATE functions (MONTH, YEAR) | Query 6 |
| ROUND, CAST | Throughout |
| Aliases (column and table) | Throughout |
| CREATE VIEW | Queries 2, 7 |
| Stored Functions | Risk categorization |
| Triggers (BEFORE INSERT) | Loan validation |
| COUNT DISTINCT | Queries 1, 6, 7 |

---

## ⚙️ How to Run

1. Open MySQL Workbench or any MySQL client
2. Create and select your database: `CREATE DATABASE banking; USE banking;`
3. Run the schema and seed data files first to set up tables
4. Run `Bank_Analysis_1.sql`, `Loan_analysis.sql`, and `Final_Report.sql` in order

---

## 👤 Author

**Prithu** — aspiring Data Analyst with a focus on SQL, banking domain analytics, and portfolio-driven learning.

[GitHub](https://github.com/PrithuVerma)
