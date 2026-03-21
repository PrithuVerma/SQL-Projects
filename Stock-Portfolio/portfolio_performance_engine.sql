use portfolio;

select * from portfolios limit 5;
select * from trades limit 5;
select * from investors limit 5;

-- # TOTAL INVESTMENTS BY PORTFOLIO ID # --

select portfolios.portfolio_id, 
round(sum(trades.quantity * trades.price_per_share),2) as total_investment
from trades
left join portfolios on trades.portfolio_id = portfolios.portfolio_id
group by portfolio_id;

-- # TRADES PER INVESTOR (BUY/SELL) # --

select investors.full_name,
COUNT(CASE WHEN trades.trade_type = 'BUY'  THEN 1 END) AS buy_trades,
COUNT(CASE WHEN trades.trade_type = 'SELL' THEN 1 END) AS sell_trades
from trades
left join portfolios on portfolios.portfolio_id = trades.portfolio_id
left join investors on investors.investor_id = portfolios.portfolio_id
group by investors.full_name;

-- # TOP 5 MOST TRADED STOCK BY VOLUME # --

select sum(daily_prices.volume) as Total_Volume, 
stocks.company_name as Company
from stocks
left join daily_prices on daily_prices.stock_id = stocks.stock_id
group by stocks.company_name
order by Total_Volume desc
limit 5;

-- # CURRENT SHARES HELD PER PORTFOLIO PER STOCK # --

select portfolios.portfolio_id as Portfolio_ID,
round(sum(case when trades.trade_type = 'BUY' then trades.quantity end) -
sum(case when trades.trade_type = 'SELL' then trades.quantity end),2) as current_stocks
from trades
left join portfolios on portfolios.portfolio_id = trades.portfolio_id
left join stocks on stocks.stock_id = trades.stock_id
group by portfolios.portfolio_id,stocks.stock_id
having current_stocks >0
order by current_stocks desc;

-- # TOTAL FEES PAID BY INVESTORS # --
select investors.full_name as Investors,
round(sum(trades.fees),2) as Total_fee_paid
from trades
left join portfolios on portfolios.portfolio_id = trades.portfolio_id
left join investors on investors.investor_id = portfolios.investor_id 
group by Investors
order by Total_fee_paid desc;

-- # portfolios that have invested more than the platform average # --

select round(avg(trades.quantity * trades.price_per_share),2) from trades;

SELECT 
    portfolios.portfolio_id,
    ROUND(SUM(trades.quantity * trades.price_per_share), 2) AS total_invested
FROM portfolios
LEFT JOIN trades ON trades.portfolio_id = portfolios.portfolio_id
GROUP BY portfolios.portfolio_id
HAVING total_invested > (
    SELECT AVG(portfolio_total)
    FROM (
        SELECT SUM(quantity * price_per_share) AS portfolio_total
        FROM trades
        GROUP BY portfolio_id
    ) AS sub
)
ORDER BY total_invested DESC;

-- # P&L ON EVERY SELL TRADE # --
	-- 1. P&L = (sell price - average buy price) × quantity sold - fees
	-- 2. Average Buy Price = SUM(quantity × price_per_share) / SUM(quantity)

-- CTE : WHAT THE INVESTORS PAID FOR EACH STOCK BY EACH PORTFOLIO
with average_buy_price as 
	(select SUM(trades.quantity * trades.price_per_share) / SUM(trades.quantity) as avg_buy_price,
    portfolio_id, stock_id
	from trades
    where trade_type = 'BUY'
    group by portfolio_id, stock_id
	)

select trades.portfolio_id, trades.stock_id,
ROUND((trades.price_per_share - average_buy_price.avg_buy_price) * trades.quantity - trades.fees, 2) AS net_pnl,
CASE 
    WHEN (trades.price_per_share - average_buy_price.avg_buy_price) * trades.quantity - trades.fees > 0 THEN 'PROFIT'
    WHEN (trades.price_per_share - average_buy_price.avg_buy_price) * trades.quantity - trades.fees < 0 THEN 'LOSS'
    WHEN (trades.price_per_share - average_buy_price.avg_buy_price) * trades.quantity - trades.fees = 0 THEN 'BREAK EVEN'
    
END AS result
from trades

left join average_buy_price on average_buy_price.stock_id = trades.stock_id
and average_buy_price.portfolio_id = trades.portfolio_id
WHERE average_buy_price.avg_buy_price IS NOT NULL
order by net_pnl;

-- # DIVIDEND PER INVESTOR # --
with holdings as (
	select trades.portfolio_id, trades.stock_id, dividends.dividend_id,
    sum(case when trades.trade_type = 'BUY' then trades.quantity else 0 end) -
    sum(case when trades.trade_type = 'SELL' then trades.quantity else 0 end) as Shares_Held
    from trades
    inner join stocks on stocks.stock_id = trades.stock_id
    inner join dividends on dividends.stock_id = stocks.stock_id
    where trades.trade_date < dividends.ex_date
    group by portfolio_id, stock_id, dividend_id
    having shares_held > 1
    )

SELECT investors.full_name, portfolios.portfolio_id,
round(sum(holdings.shares_held * dividends.amount_per_share),2) as total_dividend
from portfolios
left join investors on investors.investor_id = portfolios.investor_id
LEFT JOIN holdings ON holdings.portfolio_id = portfolios.portfolio_id
LEFT JOIN dividends ON dividends.dividend_id = holdings.dividend_id
group by investors.full_name, portfolios.portfolio_id;







