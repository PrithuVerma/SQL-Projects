import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import os

# ── PAGE CONFIG ──────────────────────────────────────────────
st.set_page_config(
    page_title="Stock Portfolio Tracker",
    page_icon="📈",
    layout="wide"
)

# ── STYLING ──────────────────────────────────────────────────
st.markdown("""
<style>
    [data-testid="stAppViewContainer"] { background-color: #0d1117; }
    [data-testid="stSidebar"] { background-color: #161b22; }
    h1, h2, h3 { color: #e6edf3; }
    .metric-card {
        background: #161b22;
        border: 1px solid #30363d;
        border-radius: 8px;
        padding: 16px 20px;
        text-align: center;
    }
    .metric-label { color: #8b949e; font-size: 13px; margin-bottom: 4px; }
    .metric-value { color: #58a6ff; font-size: 24px; font-weight: 700; }
    .profit  { color: #3fb950; font-weight: 600; }
    .loss    { color: #f85149; font-weight: 600; }
    .neutral { color: #8b949e; font-weight: 600; }
    [data-testid="stDataFrame"] { border: 1px solid #30363d; border-radius: 6px; }
</style>
""", unsafe_allow_html=True)

plt.rcParams.update({
    "figure.facecolor": "#0d1117",
    "axes.facecolor":   "#161b22",
    "axes.edgecolor":   "#30363d",
    "axes.labelcolor":  "#8b949e",
    "xtick.color":      "#8b949e",
    "ytick.color":      "#8b949e",
    "text.color":       "#e6edf3",
    "grid.color":       "#21262d",
    "grid.linestyle":   "--",
    "grid.alpha":       0.6,
})

# ── DATA LOADER ──────────────────────────────────────────────
DATA_DIR = os.path.join(os.path.dirname(__file__), "Data Tables")

@st.cache_data
def load_data():
    investors    = pd.read_csv(f"{DATA_DIR}/investors.csv")
    portfolios   = pd.read_csv(f"{DATA_DIR}/portfolios.csv")
    stocks       = pd.read_csv(f"{DATA_DIR}/stocks.csv")
    trades       = pd.read_csv(f"{DATA_DIR}/trades.csv")
    daily_prices = pd.read_csv(f"{DATA_DIR}/daily_prices.csv", parse_dates=["price_date"])
    dividends    = pd.read_csv(f"{DATA_DIR}/dividends.csv", parse_dates=["ex_date", "pay_date"])
    trades["trade_date"] = pd.to_datetime(trades["trade_date"])
    return investors, portfolios, stocks, trades, daily_prices, dividends

investors, portfolios, stocks, trades, daily_prices, dividends = load_data()

# ── SIDEBAR ──────────────────────────────────────────────────
with st.sidebar:
    st.markdown("## 📈 Portfolio Tracker")
    st.markdown("---")
    page = st.radio("Navigate", [
        "🏠 Overview",
        "💼 Portfolio AUM",
        "📊 Realised P&L",
        "🏆 Sector Rankings",
        "📈 Price & Moving Averages",
        "👥 Investor Tiers",
        "💰 Dividend Income"
    ])
    st.markdown("---")
    st.markdown(
        "<div style='color:#8b949e;font-size:12px;'>Data: yfinance + Faker (en_IN)<br>"
        "Period: Jan 2022 – Dec 2024<br>"
        "Stocks: 15 (NASDAQ / NYSE / NSE)</div>",
        unsafe_allow_html=True
    )

# ═══════════════════════════════════════════════════
# PAGE: OVERVIEW
# ═══════════════════════════════════════════════════
if page == "🏠 Overview":
    st.title("Stock Portfolio & Investment Tracker")
    st.markdown("<p style='color:#8b949e'>A production-level SQL analytics project — visualised.</p>", unsafe_allow_html=True)
    st.markdown("---")

    total_aum     = round((trades[trades["trade_type"] == "BUY"]["quantity"] * trades[trades["trade_type"] == "BUY"]["price_per_share"]).sum(), 2)
    total_trades  = len(trades)
    total_inv     = len(investors)
    total_stocks  = len(stocks)

    c1, c2, c3, c4 = st.columns(4)
    for col, label, value in zip(
        [c1, c2, c3, c4],
        ["Total AUM", "Total Trades", "Investors", "Stocks Tracked"],
        [f"${total_aum:,.0f}", total_trades, total_inv, total_stocks]
    ):
        col.markdown(f"""
        <div class='metric-card'>
            <div class='metric-label'>{label}</div>
            <div class='metric-value'>{value}</div>
        </div>""", unsafe_allow_html=True)

    st.markdown("<br>", unsafe_allow_html=True)
    c1, c2 = st.columns(2)

    with c1:
        st.subheader("Trade Volume by Sector")
        merged = trades.merge(stocks, on="stock_id")
        sector_vol = merged.groupby("sector")["quantity"].sum().sort_values()
        fig, ax = plt.subplots(figsize=(6, 3.5))
        bars = ax.barh(sector_vol.index, sector_vol.values, color=["#58a6ff","#3fb950","#f0883e"])
        ax.set_xlabel("Total Shares Traded")
        ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{x:,.0f}"))
        ax.grid(axis="x")
        plt.tight_layout()
        st.pyplot(fig)

    with c2:
        st.subheader("BUY vs SELL Distribution")
        trade_counts = trades["trade_type"].value_counts()
        fig, ax = plt.subplots(figsize=(6, 3.5))
        ax.pie(
            trade_counts.values,
            labels=trade_counts.index,
            colors=["#3fb950", "#f85149"],
            autopct="%1.1f%%",
            startangle=90,
            wedgeprops={"edgecolor": "#0d1117", "linewidth": 2}
        )
        plt.tight_layout()
        st.pyplot(fig)

# ═══════════════════════════════════════════════════
# PAGE: PORTFOLIO AUM  (Q1)
# ═══════════════════════════════════════════════════
elif page == "💼 Portfolio AUM":
    st.title("Portfolio Assets Under Management")
    st.markdown("<p style='color:#8b949e'>Total capital invested per portfolio (BUY trades only, including fees) — Q1</p>", unsafe_allow_html=True)
    st.markdown("---")

    buys = trades[trades["trade_type"] == "BUY"].copy()
    buys["trade_value"] = buys["quantity"] * buys["price_per_share"]
    aum = (
        buys.groupby("portfolio_id")
            .agg(total_invested=("trade_value", "sum"), total_fees=("fees", "sum"))
            .reset_index()
    )
    aum["total_invested"] = (aum["total_invested"] + aum["total_fees"]).round(2)
    aum = aum.merge(portfolios[["portfolio_id", "portfolio_name", "account_type"]], on="portfolio_id")
    aum = aum.sort_values("total_invested", ascending=False).reset_index(drop=True)

    c1, c2, c3 = st.columns(3)
    c1.markdown(f"<div class='metric-card'><div class='metric-label'>Highest AUM Portfolio</div><div class='metric-value'>${aum['total_invested'].max():,.0f}</div></div>", unsafe_allow_html=True)
    c2.markdown(f"<div class='metric-card'><div class='metric-label'>Average AUM</div><div class='metric-value'>${aum['total_invested'].mean():,.0f}</div></div>", unsafe_allow_html=True)
    c3.markdown(f"<div class='metric-card'><div class='metric-label'>Total Portfolios</div><div class='metric-value'>{len(aum)}</div></div>", unsafe_allow_html=True)

    st.markdown("<br>", unsafe_allow_html=True)
    top_n = st.slider("Show top N portfolios", 5, 30, 15)
    top = aum.head(top_n)

    fig, ax = plt.subplots(figsize=(10, 5))
    ax.bar(range(len(top)), top["total_invested"], color="#58a6ff", alpha=0.85)
    ax.set_xticks(range(len(top)))
    ax.set_xticklabels(top["portfolio_name"], rotation=45, ha="right", fontsize=8)
    ax.set_ylabel("Total Invested ($)")
    ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"${x:,.0f}"))
    ax.grid(axis="y")
    plt.tight_layout()
    st.pyplot(fig)

    st.markdown("#### Full Table")
    st.dataframe(
        aum[["portfolio_name", "account_type", "total_invested", "total_fees"]].rename(columns={
            "portfolio_name": "Portfolio", "account_type": "Type",
            "total_invested": "Total Invested ($)", "total_fees": "Fees ($)"
        }),
        use_container_width=True, hide_index=True
    )

# ═══════════════════════════════════════════════════
# PAGE: REALISED P&L  (Q7)
# ═══════════════════════════════════════════════════
elif page == "📊 Realised P&L":
    st.title("Realised Profit & Loss")
    st.markdown("<p style='color:#8b949e'>P&L on every SELL trade using weighted average cost basis — Q7</p>", unsafe_allow_html=True)
    st.markdown("---")

    buys = trades[trades["trade_type"] == "BUY"]
    avg_cost = (
        buys.groupby(["portfolio_id", "stock_id"])
            .apply(lambda x: (x["quantity"] * x["price_per_share"]).sum() / x["quantity"].sum())
            .reset_index(name="avg_buy_price")
    )

    sells = trades[trades["trade_type"] == "SELL"].merge(avg_cost, on=["portfolio_id", "stock_id"], how="inner")
    sells["net_pnl"] = ((sells["price_per_share"] - sells["avg_buy_price"]) * sells["quantity"] - sells["fees"]).round(2)
    sells["result"]  = sells["net_pnl"].apply(lambda x: "PROFIT" if x > 0 else ("LOSS" if x < 0 else "BREAK EVEN"))
    sells = sells.merge(stocks[["stock_id", "ticker"]], on="stock_id")

    profits = sells[sells["result"] == "PROFIT"]["net_pnl"].sum()
    losses  = sells[sells["result"] == "LOSS"]["net_pnl"].sum()
    net     = profits + losses

    c1, c2, c3 = st.columns(3)
    c1.markdown(f"<div class='metric-card'><div class='metric-label'>Total Profit</div><div class='metric-value profit'>+${profits:,.0f}</div></div>", unsafe_allow_html=True)
    c2.markdown(f"<div class='metric-card'><div class='metric-label'>Total Loss</div><div class='metric-value loss'>${losses:,.0f}</div></div>", unsafe_allow_html=True)
    c3.markdown(f"<div class='metric-card'><div class='metric-label'>Net P&L</div><div class='metric-value' style='color:{'#3fb950' if net>=0 else '#f85149'}'>${net:,.0f}</div></div>", unsafe_allow_html=True)

    st.markdown("<br>", unsafe_allow_html=True)
    c1, c2 = st.columns(2)

    with c1:
        st.subheader("P&L Distribution")
        result_counts = sells["result"].value_counts()
        colors = {"PROFIT": "#3fb950", "LOSS": "#f85149", "BREAK EVEN": "#8b949e"}
        fig, ax = plt.subplots(figsize=(5, 4))
        ax.pie(
            result_counts.values,
            labels=result_counts.index,
            colors=[colors[r] for r in result_counts.index],
            autopct="%1.1f%%",
            wedgeprops={"edgecolor": "#0d1117", "linewidth": 2}
        )
        plt.tight_layout()
        st.pyplot(fig)

    with c2:
        st.subheader("Net P&L by Stock")
        pnl_by_stock = sells.groupby("ticker")["net_pnl"].sum().sort_values()
        fig, ax = plt.subplots(figsize=(5, 4))
        bar_colors = ["#3fb950" if v >= 0 else "#f85149" for v in pnl_by_stock.values]
        ax.barh(pnl_by_stock.index, pnl_by_stock.values, color=bar_colors)
        ax.axvline(0, color="#8b949e", linewidth=0.8)
        ax.set_xlabel("Net P&L ($)")
        ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"${x:,.0f}"))
        plt.tight_layout()
        st.pyplot(fig)

    st.markdown("#### Trade-Level P&L Table")
    display = sells[["ticker", "portfolio_id", "quantity", "price_per_share", "avg_buy_price", "net_pnl", "result"]].copy()
    display.columns = ["Ticker", "Portfolio ID", "Qty", "Sell Price", "Avg Buy Price", "Net P&L ($)", "Result"]

    def color_result(val):
        if val == "PROFIT":   return "color: #3fb950"
        if val == "LOSS":     return "color: #f85149"
        return "color: #8b949e"

    st.dataframe(
        display.style.applymap(color_result, subset=["Result"]),
        use_container_width=True, hide_index=True
    )

# ═══════════════════════════════════════════════════
# PAGE: SECTOR RANKINGS  (Q9)
# ═══════════════════════════════════════════════════
elif page == "🏆 Sector Rankings":
    st.title("Stock Rankings by Sector")
    st.markdown("<p style='color:#8b949e'>Trade volume leaderboard within each sector using RANK() window function — Q9</p>", unsafe_allow_html=True)
    st.markdown("---")

    merged = trades.merge(stocks, on="stock_id")
    vol = merged.groupby(["sector", "ticker", "company_name"])["quantity"].sum().reset_index(name="total_volume")
    vol["sector_rank"] = vol.groupby("sector")["total_volume"].rank(method="min", ascending=False).astype(int)
    vol = vol.sort_values(["sector", "sector_rank"])

    sectors = vol["sector"].unique()
    cols = st.columns(len(sectors))

    for col, sector in zip(cols, sectors):
        with col:
            st.subheader(sector)
            subset = vol[vol["sector"] == sector][["sector_rank", "ticker", "total_volume"]]
            subset.columns = ["Rank", "Ticker", "Volume"]
            fig, ax = plt.subplots(figsize=(3.5, 3))
            ax.barh(subset["Ticker"][::-1], subset["Volume"][::-1], color="#58a6ff", alpha=0.85)
            ax.set_xlabel("Volume")
            ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{x:,.0f}"))
            plt.tight_layout()
            st.pyplot(fig)
            st.dataframe(subset, hide_index=True, use_container_width=True)

# ═══════════════════════════════════════════════════
# PAGE: PRICE & MOVING AVERAGES  (Q11)
# ═══════════════════════════════════════════════════
elif page == "📈 Price & Moving Averages":
    st.title("Price Trends & 7-Day Moving Average")
    st.markdown("<p style='color:#8b949e'>Real OHLCV data from Yahoo Finance with 7-day MA overlay — Q11</p>", unsafe_allow_html=True)
    st.markdown("---")

    ticker_list = stocks["ticker"].tolist()
    selected    = st.selectbox("Select Stock", ticker_list)
    stock_id    = stocks[stocks["ticker"] == selected]["stock_id"].values[0]

    price_data = daily_prices[daily_prices["stock_id"] == stock_id].sort_values("price_date").copy()
    price_data["ma_7"] = price_data["close_price"].rolling(7).mean()

    col1, col2, col3 = st.columns(3)
    col1.markdown(f"<div class='metric-card'><div class='metric-label'>Latest Close</div><div class='metric-value'>${price_data['close_price'].iloc[-1]:,.2f}</div></div>", unsafe_allow_html=True)
    col2.markdown(f"<div class='metric-card'><div class='metric-label'>52W High</div><div class='metric-value profit'>${price_data['high_price'].max():,.2f}</div></div>", unsafe_allow_html=True)
    col3.markdown(f"<div class='metric-card'><div class='metric-label'>52W Low</div><div class='metric-value loss'>${price_data['low_price'].min():,.2f}</div></div>", unsafe_allow_html=True)

    st.markdown("<br>", unsafe_allow_html=True)

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 7), gridspec_kw={"height_ratios": [3, 1]})

    ax1.plot(price_data["price_date"], price_data["close_price"], color="#58a6ff", linewidth=1.2, label="Close Price")
    ax1.plot(price_data["price_date"], price_data["ma_7"], color="#f0883e", linewidth=1.5, linestyle="--", label="7-Day MA")
    ax1.fill_between(price_data["price_date"], price_data["close_price"], alpha=0.08, color="#58a6ff")
    ax1.set_ylabel("Price ($)")
    ax1.legend(loc="upper left", facecolor="#161b22", edgecolor="#30363d")
    ax1.grid(True)
    ax1.set_title(f"{selected} — Close Price with 7-Day Moving Average", color="#e6edf3", pad=10)

    ax2.bar(price_data["price_date"], price_data["volume"], color="#8b949e", alpha=0.5, width=1)
    ax2.set_ylabel("Volume")
    ax2.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{x/1e6:.1f}M"))
    ax2.grid(True)

    plt.tight_layout()
    st.pyplot(fig)

# ═══════════════════════════════════════════════════
# PAGE: INVESTOR TIERS  (Q12)
# ═══════════════════════════════════════════════════
elif page == "👥 Investor Tiers":
    st.title("Investor Segmentation — NTILE(4)")
    st.markdown("<p style='color:#8b949e'>Investors segmented into Standard / Silver / Gold / Platinum by total investment — Q12</p>", unsafe_allow_html=True)
    st.markdown("---")

    buys = trades[trades["trade_type"] == "BUY"].copy()
    buys["trade_value"] = buys["quantity"] * buys["price_per_share"]
    port_inv = buys.groupby("portfolio_id")["trade_value"].sum().reset_index()
    port_inv = port_inv.merge(portfolios[["portfolio_id", "investor_id"]], on="portfolio_id")
    inv_totals = port_inv.groupby("investor_id")["trade_value"].sum().reset_index(name="total_invested")
    inv_totals = inv_totals.merge(investors[["investor_id", "full_name"]], on="investor_id")
    inv_totals = inv_totals.sort_values("total_invested").reset_index(drop=True)

    n = len(inv_totals)
    inv_totals["quartile"] = pd.qcut(inv_totals["total_invested"], 4, labels=[1, 2, 3, 4])
    tier_map = {1: "Standard", 2: "Silver", 3: "Gold", 4: "Platinum"}
    color_map = {"Standard": "#8b949e", "Silver": "#a8b3c5", "Gold": "#f0883e", "Platinum": "#58a6ff"}
    inv_totals["tier"] = inv_totals["quartile"].map(tier_map)

    tier_counts = inv_totals["tier"].value_counts()
    c1, c2, c3, c4 = st.columns(4)
    for col, tier in zip([c1, c2, c3, c4], ["Standard", "Silver", "Gold", "Platinum"]):
        count = tier_counts.get(tier, 0)
        col.markdown(f"""
        <div class='metric-card'>
            <div class='metric-label'>{tier}</div>
            <div class='metric-value' style='color:{color_map[tier]}'>{count} investors</div>
        </div>""", unsafe_allow_html=True)

    st.markdown("<br>", unsafe_allow_html=True)
    c1, c2 = st.columns(2)

    with c1:
        st.subheader("Investment Distribution by Tier")
        tier_avg = inv_totals.groupby("tier")["total_invested"].mean().reindex(["Standard","Silver","Gold","Platinum"])
        fig, ax = plt.subplots(figsize=(5, 4))
        bars = ax.bar(tier_avg.index, tier_avg.values, color=[color_map[t] for t in tier_avg.index], alpha=0.85)
        ax.set_ylabel("Avg Total Invested ($)")
        ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"${x:,.0f}"))
        ax.grid(axis="y")
        plt.tight_layout()
        st.pyplot(fig)

    with c2:
        st.subheader("Investor Count per Tier")
        fig, ax = plt.subplots(figsize=(5, 4))
        ax.pie(
            tier_counts.reindex(["Standard","Silver","Gold","Platinum"]).values,
            labels=["Standard","Silver","Gold","Platinum"],
            colors=[color_map[t] for t in ["Standard","Silver","Gold","Platinum"]],
            autopct="%1.1f%%",
            wedgeprops={"edgecolor":"#0d1117","linewidth":2}
        )
        plt.tight_layout()
        st.pyplot(fig)

    st.markdown("#### Investor Tier Table")
    display = inv_totals[["full_name","total_invested","tier"]].sort_values("total_invested", ascending=False)
    display.columns = ["Investor", "Total Invested ($)", "Tier"]
    st.dataframe(display, use_container_width=True, hide_index=True)

# ═══════════════════════════════════════════════════
# PAGE: DIVIDEND INCOME  (Q8)
# ═══════════════════════════════════════════════════
elif page == "💰 Dividend Income":
    st.title("Dividend Income per Investor")
    st.markdown("<p style='color:#8b949e'>Ex-date aware dividend calculation — only investors holding shares before ex_date qualify — Q8</p>", unsafe_allow_html=True)
    st.markdown("---")

    results = []
    for _, div in dividends.iterrows():
        eligible = trades[
            (trades["stock_id"] == div["stock_id"]) &
            (trades["trade_date"] < div["ex_date"])
        ].copy()
        if eligible.empty:
            continue
        eligible["signed_qty"] = eligible.apply(
            lambda r: r["quantity"] if r["trade_type"] == "BUY" else -r["quantity"], axis=1
        )
        holdings = eligible.groupby("portfolio_id")["signed_qty"].sum().reset_index()
        holdings = holdings[holdings["signed_qty"] > 0]
        holdings["dividend_income"] = holdings["signed_qty"] * div["amount_per_share"]
        holdings["dividend_id"] = div["dividend_id"]
        results.append(holdings)

    if results:
        all_holdings = pd.concat(results)
        all_holdings = all_holdings.merge(portfolios[["portfolio_id","investor_id"]], on="portfolio_id")
        inv_div = all_holdings.groupby("investor_id")["dividend_income"].sum().reset_index()
        inv_div = inv_div.merge(investors[["investor_id","full_name"]], on="investor_id")
        inv_div = inv_div.sort_values("dividend_income", ascending=False).reset_index(drop=True)
        inv_div["dividend_income"] = inv_div["dividend_income"].round(2)

        c1, c2, c3 = st.columns(3)
        c1.markdown(f"<div class='metric-card'><div class='metric-label'>Total Dividends Paid</div><div class='metric-value profit'>${inv_div['dividend_income'].sum():,.0f}</div></div>", unsafe_allow_html=True)
        c2.markdown(f"<div class='metric-card'><div class='metric-label'>Avg per Investor</div><div class='metric-value'>${inv_div['dividend_income'].mean():,.0f}</div></div>", unsafe_allow_html=True)
        c3.markdown(f"<div class='metric-card'><div class='metric-label'>Eligible Investors</div><div class='metric-value'>{len(inv_div)}</div></div>", unsafe_allow_html=True)

        st.markdown("<br>", unsafe_allow_html=True)
        top_n = st.slider("Show top N investors", 5, 30, 15)
        top   = inv_div.head(top_n)

        fig, ax = plt.subplots(figsize=(10, 5))
        ax.barh(top["full_name"][::-1], top["dividend_income"][::-1], color="#3fb950", alpha=0.85)
        ax.set_xlabel("Dividend Income ($)")
        ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"${x:,.0f}"))
        ax.grid(axis="x")
        plt.tight_layout()
        st.pyplot(fig)

        st.markdown("#### Full Dividend Table")
        inv_div.columns = ["Investor ID", "Dividend Income ($)", "Investor Name"]
        st.dataframe(inv_div[["Investor Name", "Dividend Income ($)"]], use_container_width=True, hide_index=True)
    else:
        st.warning("No dividend data found. Check that trades and dividends CSVs are populated.")