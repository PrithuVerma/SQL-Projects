USE PORTFOLIO;

# stocks rank by trade volume within each sector

with total_vol_per_stock as (
	select round(sum(trades.quantity),2) as Total_Quantity,
    stocks.stock_id as Stock
    from trades 
    left join stocks on stocks.stock_id = trades.stock_id
    group by Stock
    order by Total_Quantity desc
    )

select stocks.ticker ,
Dense_Rank() over(Partition by stocks.sector order by total_vol_per_stock.Total_Quantity desc) as Ranking
from total_vol_per_stock
left join stocks on stocks.stock_id = total_vol_per_stock.Stock;

# Running total amount invested per portfolio over time.

select portfolio_id,trade_date,
Round(SUM(quantity * price_per_share) OVER (PARTITION BY portfolio_id ORDER BY trade_date asc),2) AS running_total
from trades
order by portfolio_id desc;

# 7 day moving average of stock closing price

Select stocks.ticker, daily_prices.price_date,
Round(AVG(close_price) OVER (
    PARTITION BY daily_prices.stock_id ORDER BY price_date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
),2) as Week_Avg
from daily_prices
left join stocks on stocks.stock_id = daily_prices.stock_id;

# Investor Tiering — Standard, Silver, Gold, Platinum

WITH investor_totals AS (
    SELECT 
        i.investor_id,
        i.full_name,
        ROUND(SUM(t.quantity * t.price_per_share), 2) AS total_invested
    FROM trades t
    LEFT JOIN portfolios p ON p.portfolio_id = t.portfolio_id
    LEFT JOIN investors i ON i.investor_id = p.investor_id
    GROUP BY i.investor_id, i.full_name
)
SELECT 
    full_name,
    total_invested,
    NTILE(4) OVER (ORDER BY total_invested) AS quartile,
    CASE NTILE(4) OVER (ORDER BY total_invested)
        WHEN 1 THEN 'Standard'
        WHEN 2 THEN 'Silver'
        WHEN 3 THEN 'Gold'
        WHEN 4 THEN 'Platinum'
    END AS investor_tier
FROM investor_totals
ORDER BY total_invested DESC;


