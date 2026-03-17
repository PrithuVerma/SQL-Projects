create database PORTFOLIO;
USE PORTFOLIO; 

SELECT * FROM daily_prices LIMIT 5;
SELECT * FROM dividends LIMIT 5;
SELECT * FROM investors LIMIT 5;
SELECT * FROM PORTFOLIOS LIMIT 5;
SELECT * FROM stocks LIMIT 5;
SELECT * FROM trades LIMIT 5;


-- # PRIMARY KEY CONSTRAINT # --
alter table daily_prices
add constraint pk_daily_price primary key(price_id);
describe daily_prices;

alter table dividends
add constraint pk_dividends primary key(dividend_id);
describe dividends;

alter table investors
add constraint pk_investors primary key(investor_id);
describe investors;

alter table portfolios
add constraint pk_portfolio primary key(portfolio_id);
describe portfolios;

alter table stocks
add constraint pk_stocks primary key(stock_id);
describe stocks;

alter table trades
add constraint pk_trades primary key(trade_id);
describe trades;

-- # FOREIGN KEY CONSTRAINT # --

alter table daily_prices
	add constraint fk_daily_prices foreign key(stock_id)
    references stocks(stock_id);
Show create table daily_prices;

alter table dividends
	add constraint fk_dividends_stocks foreign key(stock_id)
    references stocks(stock_id);
Show create table dividends;
    
alter table portfolios
	add constraint fk_portfolio_investor foreign key(investor_id)
    references investors(investor_id);
Show create table portfolios;
    
alter table trades
	add constraint fk_trades_stocks foreign key(stock_id)
    references stocks(stock_id),
    add constraint fk_trades_port foreign key(portfolio_id)
    references portfolios(portfolio_id);
Show create table trades;


