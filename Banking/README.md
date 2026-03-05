# Banking Analysis SQL Project

## Overview

This project demonstrates practical **SQL data analysis skills** using a banking database. The objective is to simulate real-world banking queries that analysts and data engineers commonly perform, such as customer analysis, loan analysis, branch performance tracking, and transaction monitoring.

The database consists of multiple relational tables representing core banking entities such as **customers, accounts, loans, branches, and transactions**. Through structured SQL queries, the project extracts meaningful insights and showcases the use of advanced SQL concepts including joins, aggregations, filtering, and date analysis.

The focus of the project is to demonstrate the ability to:

* Work with **relational database schemas**
* Perform **multi-table joins**
* Use **aggregation and grouping techniques**
* Apply **filtering conditions and business logic**
* Analyze **time-based financial data**
* Build **complex analytical queries**

---

## Database Structure

The project uses a normalized banking schema composed of the following tables:

* **customers** – stores customer personal information
* **accounts** – contains bank account details
* **transactions** – records all account transactions
* **loans** – holds loan information issued to customers
* **branches** – contains branch location and management data

These tables are connected through **primary keys and foreign keys**, reflecting real banking system relationships.

---

## SQL Analysis Performed

The following analyses were implemented to extract insights from the banking dataset.

| # | Analysis                                      | Tables Involved                 | Concepts Used          |
| - | --------------------------------------------- | ------------------------------- | ---------------------- |
| 1 | Customer account summary                      | customers + accounts            | JOIN, GROUP BY         |
| 2 | Branch wise account distribution              | accounts + branches             | JOIN, COUNT, GROUP BY  |
| 3 | Top 10 high value loans with customer details | loans + customers               | JOIN, ORDER BY, LIMIT  |
| 4 | Customers with multiple active loans          | loans + customers               | JOIN, GROUP BY, HAVING |
| 5 | Transaction summary per account               | transactions + accounts         | JOIN, SUM, AVG         |
| 6 | Customers with accounts in multiple cities    | accounts + branches + customers | MULTI TABLE JOIN       |
| 7 | Monthly transaction trends                    | transactions                    | DATE functions         |
| 8 | Complete customer 360 view                    | ALL 5 TABLES                    | Complex JOIN           |

---

## Key SQL Concepts Demonstrated

This project highlights the practical use of important SQL concepts:

* **INNER JOIN and multi-table joins**
* **GROUP BY and aggregate functions**
* **HAVING clause for grouped filtering**
* **ORDER BY and LIMIT for ranking**
* **COUNT, SUM, AVG for financial summaries**
* **Date functions for time-series analysis**
* **Complex queries combining multiple entities**

---

## Purpose of the Project

The goal of this project is to demonstrate the ability to:

* Design and query **relational database schemas**
* Write **analytical SQL queries**
* Extract **business insights from financial data**
* Work with **multi-table banking datasets**

This type of analysis is commonly used in:

* Banking analytics
* Financial reporting
* Customer segmentation
* Loan risk analysis
* Transaction monitoring

---

## Potential Extensions

Future improvements could include:

* Adding **views** for reusable analytics queries
* Creating **stored procedures** for automated reports
* Implementing **indexes for query optimization**
* Building a **Power BI or Tableau dashboard** connected to the database
* Adding **fraud detection queries based on transaction patterns**

---

## Schema
<img width="664" height="454" alt="Screenshot 2026-03-03 at 8 15 00 PM" src="https://github.com/user-attachments/assets/17c253b8-7076-4cfd-a6bf-5064f689e96d" />
