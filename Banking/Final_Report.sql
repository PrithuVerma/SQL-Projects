use Banking;
show Tables;

select * from customers limit 10;
select * from accounts limit 10;

select account_type, balance from customers
left join accounts on customers.customer_id = accounts.customer_id;

SELECT customers.customer_id, customers.name, 
       accounts.account_type, accounts.balance
FROM customers
LEFT JOIN accounts ON customers.customer_id = accounts.customer_id;

SELECT customers.customer_id, customers.name, 
       COUNT(accounts.account_id) AS total_accounts,
       round(SUM(accounts.balance),2) AS total_balance
FROM customers
LEFT JOIN accounts ON customers.customer_id = accounts.customer_id
GROUP BY customers.customer_id, customers.name;

-- Branch wise account distribution

select branches.branch_name , branches.city, 
count(account_id) as total_accounts
from branches
left join accounts on accounts.branch_id = branches.branch_id
group by branches.branch_name , branches.city
order by total_accounts desc;

-- Top 10 high value loans with customer details

select customers.name,customers.customer_id,
MAX(loans.loan_amount) as loan_amt
from customers
left join loans on loans.customer_id = customers.customer_id
group by customers.name,customers.customer_id
order by loan_amt desc
limit 10;

-- Views  
create VIEW top_loan_exposure as 
select customers.name,customers.customer_id,
SUM(loans.loan_amount) as total_loan_exposure
from customers
left join loans on loans.customer_id = customers.customer_id
group by customers.name,customers.customer_id
order by total_loan_exposure desc
limit 10;

select * from top_loan_exposure;

create view branch_wise_dist as 
select branches.branch_name , branches.city, 
count(account_id) as total_accounts
from branches
left join accounts on accounts.branch_id = branches.branch_id
group by branches.branch_name , branches.city
order by total_accounts desc;

SELECT * FROM branch_wise_dist;

-- Customers with multiple active loans

select customers.name, customers.customer_id, 
count(loans.loan_status) as loan_stats
from customers left join loans on customers.customer_id = loans.customer_id
where loans.loan_status = 'Active'
group by customers.name, customers.customer_id 
having count(loans.loan_status) > 1 ;

-- Transaction Summary per account

select accounts.account_type,
round(sum(transactions.amount),2) as CD_amount, 
transactions.transaction_type as TransactionType,
count(transactions.transaction_id) as Transaction_Count
from transactions
right join accounts on transactions.account_id = accounts.account_id
group by accounts.account_type,transactions.transaction_type;

select accounts.account_type,
round(sum(transactions.amount),2) as CD_amount, 
transactions.transaction_type as TransactionType,
count(transactions.transaction_id) as Transaction_Count
from transactions
left join accounts on transactions.account_id = accounts.account_id
group by accounts.account_type,transactions.transaction_type;

-- Custom/Stored Functions
DELIMITER $$

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
END $$

DELIMITER ;

SELECT name, loans.loan_amount, getRiskCategory(loans.loan_amount) AS risk_category
FROM customers
INNER JOIN loans ON customers.customer_id = loans.customer_id;

-- JOINS for more than 2 tables

-- Customers with accounts in multiple cities

select customers.name, count(distinct branches.city) as city_count
from customers
left join accounts on customers.customer_id = accounts.customer_id
left join branches on branches.branch_id = accounts.branch_id
group by customers.name
having count(distinct branches.city) > 1;

-- verification of previous query
select customers.name, branches.city
from customers
left join accounts on customers.customer_id = accounts.customer_id
left join branches on branches.branch_id = accounts.branch_id
order by customers.name;

-- Monthly transaction trends

select month(transaction_date) as months,
year(transaction_date) as years,
round(sum(amount),2) as total_amount,
count(transaction_id) as transaction_id
from transactions
group by year(transaction_date), month(transaction_date)
order by year(transaction_date),month(transaction_date);

-- Trigger to check outlier
DELIMITER $$

CREATE TRIGGER validate_loan_amount
BEFORE INSERT ON loans
FOR EACH ROW
BEGIN
    IF NEW.loan_amount < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Loan amount cannot be negative';
    END IF;
END $$

DELIMITER ;

INSERT INTO loans (loan_id, customer_id, loan_amount, interest_rate, loan_status)
VALUES (9999, 1, -50000, 5.5, 'Active');

SELECT * FROM loans WHERE loan_id = 9999;

-- Customer 360 View using all 5 tables

-- 1. Transactions - Accounts via account_id
-- 2. Accounts - Customers via customer_id
-- 3. Accounts - Branches via branch_id
-- 4. Transactions - Accounts via account_id
-- 5. Loans - Customers via customer_id
-- 6. No direct relation between Transaction, Loans and Branches
-- 7. No direct relation between Transaction and Customers, Loans and Branches, Branches and Customers, Transaction and Branches

-- Total Joins required to connect all 5 tables is 4

select * from customers
left join accounts on accounts.customer_id = customers.customer_id
left join transactions on accounts.account_id = transactions.account_id
left join branches on accounts.branch_id = branches.branch_id
left join loans on customers.customer_id = loans.customer_id;

CREATE VIEW CUSTOMER_360 AS
SELECT 
    c.customer_id,
    c.name,
    c.city,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    ROUND(SUM(a.balance),2) AS total_balance,
    b.branch_name,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    ROUND(SUM(l.loan_amount),2) AS total_loan_exposure,
    COUNT(DISTINCT t.transaction_id) AS total_transactions
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN branches b ON a.branch_id = b.branch_id
LEFT JOIN loans l ON c.customer_id = l.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY c.customer_id, c.name, c.city, b.branch_name;

