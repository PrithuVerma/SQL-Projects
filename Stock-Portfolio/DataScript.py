import csv
import random
from datetime import date, timedelta
from faker import Faker
import yfinance as yf
import pandas as pd
import os

fake = Faker('en_IN')   # Indian locale: Indian names, cities, phone numbers
random.seed(42)
os.makedirs("datasets", exist_ok=True)

# ── CONFIG ──────────────────────────────────────────────────
NUM_INVESTORS   = 100
NUM_PORTFOLIOS  = 150   # some investors have multiple
NUM_TRADES      = 600
PRICE_START     = date(2022, 1, 1)
PRICE_END       = date(2024, 12, 31)

TICKERS = [
    "AAPL", "MSFT", "GOOGL", "AMZN", "META",
    "JPM",  "BAC",  "GS",   "JNJ",  "PFE",
    "INFY", "TCS.NS", "RELIANCE.NS", "HDFCBANK.NS", "WIPRO.NS"
]

SECTORS = {
    "AAPL": "Technology",  "MSFT": "Technology",  "GOOGL": "Technology",
    "AMZN": "Technology",  "META": "Technology",   "JPM":  "Finance",
    "BAC":  "Finance",     "GS":   "Finance",      "JNJ":  "Healthcare",
    "PFE":  "Healthcare",  "INFY": "Technology",   "TCS.NS": "Technology",
    "RELIANCE.NS": "Energy","HDFCBANK.NS": "Finance","WIPRO.NS": "Technology"
}

EXCHANGES = {
    "AAPL": "NASDAQ", "MSFT": "NASDAQ", "GOOGL": "NASDAQ", "AMZN": "NASDAQ",
    "META": "NASDAQ", "JPM": "NYSE",    "BAC": "NYSE",     "GS": "NYSE",
    "JNJ": "NYSE",    "PFE": "NYSE",    "INFY": "NYSE",
    "TCS.NS": "NSE",  "RELIANCE.NS": "NSE", "HDFCBANK.NS": "NSE", "WIPRO.NS": "NSE"
}

COMPANIES = {
    "AAPL": "Apple Inc.",           "MSFT": "Microsoft Corporation",
    "GOOGL": "Alphabet Inc.",       "AMZN": "Amazon.com Inc.",
    "META": "Meta Platforms Inc.",  "JPM": "JPMorgan Chase & Co.",
    "BAC": "Bank of America Corp.", "GS": "Goldman Sachs Group Inc.",
    "JNJ": "Johnson & Johnson",     "PFE": "Pfizer Inc.",
    "INFY": "Infosys Limited",      "TCS.NS": "Tata Consultancy Services",
    "RELIANCE.NS": "Reliance Industries", "HDFCBANK.NS": "HDFC Bank Ltd.",
    "WIPRO.NS": "Wipro Limited"
}

ACCOUNT_TYPES = ["Demat", "NPS", "ELSS", "General"]
CURRENCIES    = ["INR"]

# ── 1. INVESTORS ─────────────────────────────────────────────
print("Generating investors.csv ...")
investors = []
for i in range(1, NUM_INVESTORS + 1):
    investors.append({
        "investor_id": i,
        "full_name":   fake.name(),
        "email":       fake.unique.email(),
        "joined_date": fake.date_between(start_date=date(2018,1,1), end_date=date(2023,1,1))
    })

with open("datasets/investors.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=investors[0].keys())
    writer.writeheader()
    writer.writerows(investors)

# ── 2. PORTFOLIOS ────────────────────────────────────────────
print("Generating portfolios.csv ...")
portfolios = []
for i in range(1, NUM_PORTFOLIOS + 1):
    investor = random.choice(investors)
    acc_type = random.choice(ACCOUNT_TYPES)
    portfolios.append({
        "portfolio_id":   i,
        "investor_id":    investor["investor_id"],
        "portfolio_name": f"{investor['full_name'].split()[0]} {acc_type} {random.randint(1,3)}",
        "account_type":   acc_type,
        "currency":       random.choice(CURRENCIES),
        "created_date":   fake.date_between(
                            start_date=investor["joined_date"],
                            end_date=date(2023, 6, 1))
    })

with open("datasets/portfolios.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=portfolios[0].keys())
    writer.writeheader()
    writer.writerows(portfolios)

# ── 3. STOCKS ────────────────────────────────────────────────
print("Generating stocks.csv ...")
stocks = []
for i, ticker in enumerate(TICKERS, start=1):
    stocks.append({
        "stock_id":     i,
        "ticker":       ticker,
        "company_name": COMPANIES[ticker],
        "sector":       SECTORS[ticker],
        "exchange":     EXCHANGES[ticker]
    })

with open("datasets/stocks.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=stocks[0].keys())
    writer.writeheader()
    writer.writerows(stocks)

stock_id_map = {s["ticker"]: s["stock_id"] for s in stocks}

# ── 4. TRADES ────────────────────────────────────────────────
print("Generating trades.csv ...")
trades = []
for i in range(1, NUM_TRADES + 1):
    portfolio = random.choice(portfolios)
    stock     = random.choice(stocks)
    is_indian = stock["ticker"].endswith(".NS")
    price     = round(random.uniform(500, 3500) if is_indian else random.uniform(50, 400), 2)
    trades.append({
        "trade_id":        i,
        "portfolio_id":    portfolio["portfolio_id"],
        "stock_id":        stock["stock_id"],
        "trade_type":      random.choices(["BUY", "SELL"], weights=[70, 30])[0],
        "quantity":        round(random.uniform(1, 100), 2),
        "price_per_share": price,
        "trade_date":      fake.date_between(start_date=date(2022,1,1), end_date=date(2024,6,1)),
        "fees":            round(random.uniform(0, 25), 2)
    })

with open("datasets/trades.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=trades[0].keys())
    writer.writeheader()
    writer.writerows(trades)

# ── 5. DAILY PRICES (real data from yfinance) ────────────────
print("Fetching real price data from Yahoo Finance (this takes ~30 seconds) ...")
all_prices = []
price_id   = 1

for ticker in TICKERS:
    print(f"  Downloading {ticker} ...")
    try:
        df = yf.download(ticker, start=PRICE_START, end=PRICE_END,
                        auto_adjust=True, progress=False)
        df = df.dropna()
        sid = stock_id_map[ticker]
        for row_date, row in df.iterrows():
            all_prices.append({
                "price_id":    price_id,
                "stock_id":    sid,
                "price_date":  row_date.date(),
                "open_price":  round(float(row["Open"]),  4),
                "close_price": round(float(row["Close"]), 4),
                "high_price":  round(float(row["High"]),  4),
                "low_price":   round(float(row["Low"]),   4),
                "volume":      int(row["Volume"])
            })
            price_id += 1
    except Exception as e:
        print(f"  Warning: could not fetch {ticker}: {e}")

with open("datasets/daily_prices.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=all_prices[0].keys())
    writer.writeheader()
    writer.writerows(all_prices)

print(f"  daily_prices.csv → {len(all_prices)} rows")

# ── 6. DIVIDENDS ─────────────────────────────────────────────
print("Generating dividends.csv ...")
div_stocks  = [s for s in stocks if s["ticker"] in ("AAPL","MSFT","JPM","JNJ","PFE","HDFCBANK.NS","TCS.NS")]
dividends   = []
dividend_id = 1

for stock in div_stocks:
    is_indian   = stock["ticker"].endswith(".NS")
    num_divs    = random.randint(3, 8)
    current     = date(2022, 3, 1)
    for _ in range(num_divs):
        ex   = current + timedelta(days=random.randint(80, 100))
        pay  = ex + timedelta(days=random.randint(10, 20))
        if ex > date(2024, 12, 31):
            break
        dividends.append({
            "dividend_id":      dividend_id,
            "stock_id":         stock["stock_id"],
            "ex_date":          ex,
            "pay_date":         pay,
            "amount_per_share": round(random.uniform(8, 35) if is_indian else random.uniform(0.2, 1.5), 4)
        })
        dividend_id += 1
        current = pay

with open("datasets/dividends.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=dividends[0].keys())
    writer.writeheader()
    writer.writerows(dividends)

# ── SUMMARY ──────────────────────────────────────────────────
print("\n✅ All CSVs generated in /datasets folder:")
for fname in os.listdir("datasets"):
    path  = f"datasets/{fname}"
    lines = sum(1 for _ in open(path)) - 1
    print(f"   {fname:<25} → {lines} rows")