# 📈 Stock Portfolio & Investment Tracker — SQL Project

A multi-table relational database project built to demonstrate production-level SQL skills in a finance/investment domain. Designed for data analyst roles.

---

## What This Project Does

This database models a simplified investment platform where investors manage stock portfolios, execute trades, and receive dividends. It answers real business questions like:

- How much has each investor deployed across their portfolios?
- What is the running P&L on every portfolio over time?
- Which stocks have the highest momentum within their sector?
- How much dividend income has each investor earned?

These are the kinds of questions a data analyst at a fintech, investment bank, or wealth management firm would be asked to answer on day one.

---

## Schema Overview

```
investors ──< portfolios ──< trades >── stocks
                                  └──< daily_prices
                                  └──< dividends
```

| Table | Purpose | Key Columns |
|---|---|---|
| `investors` | Platform users who own portfolios | investor_id, country |
| `portfolios` | An investor can hold multiple accounts | account_type, currency |
| `stocks` | Tradeable instruments (equities only) | ticker, sector, exchange |
| `trades` | Every BUY/SELL transaction — the fact table | quantity, price_per_share, fees |
| `daily_prices` | Historical OHLCV data per stock | close_price, volume |
| `dividends` | Dividend payouts with ex_date logic | amount_per_share, ex_date |

**Why this is a star schema:** `trades` and `daily_prices` are fact tables (high volume, numeric events). Everything else is a dimension (descriptive context). This mirrors how real financial databases are structured.

---

## Project Structure

```
stock-portfolio/
├── schema.sql                              # Table definitions + indexes
├── seed_data.sql                           # Realistic sample data
├── queries/
│   ├── tier1_joins/
│   │   └── 01_joins_and_aggregations.sql   # JOINs, GROUP BY, CASE WHEN
│   ├── tier2_subqueries/
│   │   └── 02_subqueries_and_ctes.sql      # CTEs, correlated subqueries, NOT EXISTS
│   └── tier3_window_functions/
│       └── 03_window_functions.sql         # RANK, SUM OVER, LAG, NTILE, moving averages
```

---

## Query Highlights

### Tier 1 — JOINs & Aggregations
Business question answered by each query:

| Query | Business Question |
|---|---|
| Total capital per portfolio | AUM breakdown |
| Trades per investor | Active vs passive investor segmentation |
| Most traded stocks | Popular instruments on the platform |
| Current holdings (net position) | Open position sizing |
| Sector allocation | Diversification analysis |

**Key technique:** Conditional aggregation using `SUM(CASE WHEN trade_type = 'BUY' THEN quantity ELSE -quantity END)` to compute net share holdings without a subquery.

---

### Tier 2 — Subqueries & CTEs
| Query | Business Question |
|---|---|
| Above-average portfolios | High-value client identification |
| P&L on every SELL trade | Trade-level performance reporting |
| Dividend income per investor | Income summary for tax reporting |
| Buy-and-hold positions | Long-term conviction analysis |
| Full portfolio health dashboard | Executive summary using chained CTEs |

**Key technique:** Chained CTEs — splitting a complex multi-step calculation into named, readable intermediate steps instead of nesting subqueries three levels deep.

---

### Tier 3 — Window Functions

| Function | Query | Business Use |
|---|---|---|
| `RANK()` / `DENSE_RANK()` | Stocks by volume within sector | Sector leaderboard |
| `SUM() OVER` (cumulative) | Running total invested per portfolio | Capital deployment timeline |
| `AVG() OVER` with `ROWS BETWEEN` | 7-day moving average price | Price trend smoothing |
| `LAG()` | Compare trade price to previous trade | Cost averaging analysis |
| `SUM() OVER` (full partition) | Stock % of total portfolio | Concentration risk |
| `NTILE(4)` | Investor quartile tiering | Customer segmentation |
| `FIRST_VALUE()` / `LAST_VALUE()` | Entry price vs latest trade price | Unrealised gain/loss |

**The key distinction vs GROUP BY:** Window functions keep every individual row. GROUP BY collapses them. This matters when you need both the detail row *and* the aggregate on the same output line.

---

## How to Run

```sql
-- 1. Create and select your database
CREATE DATABASE stock_portfolio;
USE stock_portfolio;

-- 2. Build the schema
SOURCE schema.sql;

-- 3. Load the seed data
SOURCE seed_data.sql;

-- 4. Run any query file
SOURCE queries/tier3_window_functions/03_window_functions.sql;
```

Compatible with: MySQL 8.0+, MariaDB 10.6+

---

## Production Considerations

Things this project accounts for that a beginner project typically does not:

- **Indexes** on high-traffic columns (`trade_date`, `portfolio_id`, `price_date`) to prevent full table scans
- **UNIQUE constraint** on `(stock_id, price_date)` in `daily_prices` to prevent duplicate price records
- **LEFT JOIN** used deliberately in portfolio summary — not all portfolios have SELL trades, and an INNER JOIN would silently drop them
- **`COALESCE`** to handle NULL values from LEFT JOINs rather than letting NULLs propagate into calculations
- **`LAST_VALUE` frame clause** explicitly set to `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` — without this, MySQL defaults the frame to the current row, producing incorrect results
- **Fees included** in P&L calculations — a common oversight in demo projects

---

## Related Projects

- [Banking Schema & Queries](https://github.com/PrithuVerma/SQL-Projects/tree/main/Banking)— account management, transactions, loan tracking

---

*Built as part of a SQL portfolio series targeting data analyst roles in the finance domain.*
