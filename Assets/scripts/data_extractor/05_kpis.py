"""
Builds:
    05_kpis_by_customer_segment.csv   long-format KPIs (one metric per row)

Sources:
    Axis Bank Press release for additional metrics.pdf  (pages 1-8)
    Axis Bank earnings call Conference Data.pdf          (pages 3-7)
    Axis Bank Data file 1.pdf                            (page 1, NPA amounts and ratios)

Basis column: QAB = quarterly average balance, MEB = month-end balance.
"""

import pandas as pd
from common import DATA_FILE, PRESS, CALL, Checker, save

rows = []


def kpi(theme, segment, metric, value, unit, period, source, page, basis=""):
    rows.append(dict(theme=theme, customer_segment=segment, metric=metric, value=value, unit=unit,
                     period=period, basis=basis, source_file=source, source_page=page))


# ---------------------------------------------------------------- Margins & returns
T = "Margins & returns"
kpi(T, "Bank", "Net interest margin", 3.46, "%", "Q1FY27", PRESS, 2)
kpi(T, "Bank", "NIM change YoY", -34, "bps", "Q1FY27", CALL, 6)
kpi(T, "Bank", "NIM change QoQ", -16, "bps", "Q1FY27", CALL, 6)
kpi(T, "Bank", "NIM YoY decline due to repo rate cuts", -19, "bps", "Q1FY27", CALL, 6)
kpi(T, "Bank", "NIM YoY decline due to balance sheet mix", -16, "bps", "Q1FY27", CALL, 6)
kpi(T, "Bank", "Cost of funds change YoY", -35, "bps", "Q1FY27", PRESS, 2)
kpi(T, "Bank", "Cost of funds change QoQ", -2, "bps", "Q1FY27", PRESS, 2)
kpi(T, "Bank", "Return on average assets (annualized)", 1.51, "%", "Q1FY27", PRESS, 7)
kpi(T, "Bank", "Return on average assets (annualized)", 1.47, "%", "Q1FY26", PRESS, 7)
kpi(T, "Bank", "Return on equity (annualized)", 14.16, "%", "Q1FY27", PRESS, 7)
kpi(T, "Bank", "Return on equity (annualized)", 13.14, "%", "Q1FY26", PRESS, 7)
kpi(T, "Group", "Consolidated ROA (annualized)", 1.56, "%", "Q1FY27", CALL, 5)
kpi(T, "Group", "Consolidated ROE (annualized)", 14.52, "%", "Q1FY27", CALL, 5)
kpi(T, "Bank", "Cost to assets", 2.20, "%", "Q1FY27", PRESS, 1)
kpi(T, "Bank", "Fee to assets", 1.30, "%", "Q1FY27", CALL, 6)
kpi(T, "Bank", "Technology & digital share of opex", 11, "%", "Q1FY27", CALL, 6, "approx.")
kpi(T, "Bank", "Floating-rate share of loans", 74, "%", "Q1FY27", CALL, 7, "approx.")

# ---------------------------------------------------------------- Operating performance (press release p7)
T = "Operating performance"
for metric, q1fy27, q1fy26 in [
    ("Net interest income", 14646, 13560), ("Other income", 6735, 7258), ("Fee income", 6156, 5746),
    ("Trading income", 537, 1420), ("Miscellaneous income", 42, 92), ("Operating revenue", 21382, 20818),
    ("Core operating revenue (ex trading)", 20844, 19398), ("Operating expenses", 9722, 9303),
    ("Operating profit", 11659, 11515), ("Core operating profit (ex trading)", 11122, 10095), ("Net profit", 7114, 5806),
]:
    kpi(T, "Bank", metric, q1fy27, "INR crore", "Q1FY27", PRESS, 7)
    kpi(T, "Bank", metric, q1fy26, "INR crore", "Q1FY26", PRESS, 7)

# ---------------------------------------------------------------- Fees by customer segment
T = "Fees"
kpi(T, "Retail", "Retail fees share of total fees", 67, "%", "Q1FY27", PRESS, 3)
kpi(T, "Retail", "Retail fees growth YoY", 2, "%", "Q1FY27", PRESS, 3)
kpi(T, "Corporate & Commercial", "Corporate & commercial banking fees", 2004, "INR crore", "Q1FY27", PRESS, 3)
kpi(T, "Corporate & Commercial", "Corporate & commercial banking fees growth YoY", 18, "%", "Q1FY27", PRESS, 3)
kpi(T, "Corporate & Commercial", "Corporate & commercial banking fees growth QoQ", 16, "%", "Q1FY27", PRESS, 3)
kpi(T, "Bank", "Granular fees share of total fees", 90, "%", "Q1FY27", PRESS, 1)

# ---------------------------------------------------------------- Deposits & CASA
T = "Deposits & CASA"
for metric, value, basis in [
    ("Total deposits growth YoY", 18, "QAB"), ("Term deposits growth YoY", 21, "QAB"),
    ("Current account growth YoY", 13, "QAB"), ("Savings account growth YoY", 14, "QAB"), ("CASA growth YoY", 13, "QAB"),
    ("Total deposits growth YoY", 18, "MEB"), ("Term deposits growth YoY", 23, "MEB"),
    ("Current account growth YoY", 6, "MEB"), ("Savings account growth YoY", 14, "MEB"), ("CASA growth YoY", 11, "MEB"),
    ("Total deposits growth QoQ", 6, "QAB"), ("Term deposits growth QoQ", 7, "QAB"),
    ("Current account growth QoQ", 3, "QAB"), ("Savings account growth QoQ", 6, "QAB"), ("CASA growth QoQ", 5, "QAB"),
    ("Total deposits growth QoQ", 3, "MEB"), ("Term deposits growth QoQ", 5, "MEB"),
    ("Current account growth QoQ", -6, "MEB"), ("Savings account growth QoQ", 1, "MEB"), ("CASA growth QoQ", -1, "MEB"),
    ("CASA ratio", 37, "QAB"), ("CASA ratio", 38, "MEB"),
]:
    page = 2 if ("QoQ" in metric or metric == "CASA ratio") else 1
    kpi(T, "Bank", metric, value, "%", "Q1FY27", PRESS, page, basis)
kpi(T, "Bank", "CASA ratio", 40, "%", "Q1FY26", PRESS, 8, "MEB")
kpi(T, "Bank", "CASA ratio", 38, "%", "Q1FY26", PRESS, 8, "QAB")
kpi(T, "Retail", "NTB average balances growth YoY", 18, "%", "Q1FY27", CALL, 3)
kpi(T, "Retail", "Corporate salary NTB average balance growth YoY", 30, "%", "Q1FY27", CALL, 3)
kpi(T, "Retail", "Existing-to-bank salary book growth YoY", 18, "%", "Q1FY27", CALL, 3)
kpi(T, "Retail", "SA accounts opened via tab banking", 66, "%", "Q1FY27", PRESS, 4)
kpi(T, "Retail", "Individual retail TDs opened digitally (by value)", 48, "%", "Q1FY27", PRESS, 4)
kpi(T, "Wealth", "Burgundy wealth AUM", 753819, "INR crore", "Q1FY27", PRESS, 5)
kpi(T, "Wealth", "Burgundy Private AUM", 268058, "INR crore", "Q1FY27", PRESS, 5)
kpi(T, "Wealth", "Burgundy Private families", 17408, "count", "Q1FY27", PRESS, 5)

# ---------------------------------------------------------------- Loans
T = "Loans"
kpi(T, "Retail", "Retail share of advances", 54, "%", "Q1FY27", CALL, 7)
kpi(T, "Corporate", "Corporate share of advances", 34, "%", "Q1FY27", CALL, 7)
kpi(T, "Commercial Banking Group (CBG)", "CBG share of advances", 12, "%", "Q1FY27", CALL, 7)
kpi(T, "SME", "SME loans growth QoQ", 3, "%", "Q1FY27", PRESS, 1)
kpi(T, "Corporate", "Corporate loans growth QoQ", 5, "%", "Q1FY27", PRESS, 1)
kpi(T, "Mid-Corporate", "Mid-corporate loans growth YoY", 27, "%", "Q1FY27", PRESS, 1)
kpi(T, "Mid-Corporate", "Mid-corporate loans growth QoQ", 10, "%", "Q1FY27", PRESS, 4)
kpi(T, "SBB + SME + Mid-Corporate", "SBB+SME+MC loans", 306100, "INR crore", "Q1FY27", PRESS, 1, "reported as INR 3,061 bn")
kpi(T, "SBB + SME + Mid-Corporate", "SBB+SME+MC share of total loans", 24, "%", "Q1FY27", PRESS, 1)
kpi(T, "SBB + SME + Mid-Corporate", "SBB+SME+MC growth YoY", 24, "%", "Q1FY27", PRESS, 2)
kpi(T, "Corporate", "Corporate book rated A- and above", 91, "%", "Q1FY27", PRESS, 4)
kpi(T, "Corporate", "Incremental corporate sanctions rated A- and above", 87, "%", "Q1FY27", PRESS, 4)
for metric, value in [
    ("Small Business Banking growth YoY", 18), ("Small Business Banking growth QoQ", 2),
    ("Loan against property growth YoY", 11), ("Personal loans growth YoY", 7),
    ("Credit card advances growth YoY", 5), ("Rural loans growth YoY", 16),
    ("Secured share of retail loans", 73), ("Home loans share of retail book", 26),
]:
    kpi(T, "Retail", metric, value, "%", "Q1FY27", PRESS, 4)
for metric, value in [
    ("Retail disbursement growth YoY", 18), ("Home loan disbursement growth YoY", 24),
    ("Vehicle loan disbursement growth YoY", 21), ("Retail agri disbursement growth YoY", 16),
    ("Personal loan disbursement growth YoY", 23),
]:
    kpi(T, "Retail", metric, value, "%", "Q1FY27", CALL, 7)

# ---------------------------------------------------------------- Credit cards
T = "Credit cards"
kpi(T, "Retail", "New credit cards issued", 0.92, "million", "Q1FY27", PRESS, 4)
kpi(T, "Retail", "Cards-in-force market share", 13.4, "%", "Q1FY27", PRESS, 1, "RBI data May-26")

# ---------------------------------------------------------------- Asset quality (credit given)
T = "Asset quality"
kpi(T, "Bank", "Gross NPA ratio", 1.28, "%", "Q1FY27", DATA_FILE, 1)
kpi(T, "Bank", "Gross NPA ratio", 1.23, "%", "Q4FY26", DATA_FILE, 1)
kpi(T, "Bank", "Gross NPA ratio", 1.57, "%", "Q1FY26", DATA_FILE, 1)
kpi(T, "Bank", "Net NPA ratio", 0.39, "%", "Q1FY27", DATA_FILE, 1)
kpi(T, "Bank", "Net NPA ratio", 0.37, "%", "Q4FY26", DATA_FILE, 1)
kpi(T, "Bank", "Net NPA ratio", 0.45, "%", "Q1FY26", DATA_FILE, 1)
kpi(T, "Bank", "Gross NPA amount", 17124.33, "INR crore", "Q1FY27", DATA_FILE, 1)
kpi(T, "Bank", "Gross NPA amount", 16083.65, "INR crore", "Q4FY26", DATA_FILE, 1)
kpi(T, "Bank", "Gross NPA amount", 17764.66, "INR crore", "Q1FY26", DATA_FILE, 1)
kpi(T, "Bank", "Net NPA amount", 5192.56, "INR crore", "Q1FY27", DATA_FILE, 1)
kpi(T, "Bank", "Net NPA amount", 4789.59, "INR crore", "Q4FY26", DATA_FILE, 1)
kpi(T, "Bank", "Net NPA amount", 5065.99, "INR crore", "Q1FY26", DATA_FILE, 1)
kpi(T, "Bank", "Provision coverage ratio", 70, "%", "Q1FY27", PRESS, 2)
kpi(T, "Bank", "Net credit cost (annualized)", 0.63, "%", "Q1FY27", PRESS, 2)
kpi(T, "Bank", "Net credit cost", 2079, "INR crore", "Q1FY27", CALL, 7)
kpi(T, "Bank", "Gross slippage ratio (annualized)", 1.79, "%", "Q1FY27", PRESS, 2)
kpi(T, "Bank", "Net slippage ratio (annualized)", 1.12, "%", "Q1FY27", PRESS, 2)

# Slippages (loans turning bad) by customer segment, earnings call p7
SLIPPAGES = [  # (segment, gross, net, net adjusted for write-off recoveries)
    ("Retail", 5176, 3204, 2614),
    ("CBG", 266, 210, 136),
    ("Wholesale (WBCG)", 124, 26, -271),
    ("Bank", 5566, 3440, 2479),
]
for segment, gross, net, net_adj in SLIPPAGES:
    kpi(T, segment, "Gross slippages", gross, "INR crore", "Q1FY27", CALL, 7)
    kpi(T, segment, "Net slippages", net, "INR crore", "Q1FY27", CALL, 7)
    kpi(T, segment, "Net slippages adj. for write-off recoveries", net_adj, "INR crore", "Q1FY27", CALL, 7)

chk = Checker("05 KPIs")
chk.equal("Gross slippages split", 5176 + 266 + 124, 5566)
chk.equal("Net slippages split", 3204 + 210 + 26, 3440)
chk.equal("Net adjusted slippages split", 2614 + 136 - 271, 2479)

kpi(T, "Bank", "Recoveries from written-off accounts", 961, "INR crore", "Q1FY27", PRESS, 5)
kpi(T, "Bank", "Recoveries and upgrades from NPAs", 2126, "INR crore", "Q1FY27", PRESS, 5)
kpi(T, "Bank", "NPA write-offs", 2399, "INR crore", "Q1FY27", PRESS, 5)
kpi(T, "Bank", "Cumulative non-NPA provisions", 15608, "INR crore", "Q1FY27", PRESS, 3)

# ---------------------------------------------------------------- Capital
T = "Capital"
kpi(T, "Bank", "Capital adequacy ratio", 16.67, "%", "Q1FY27", PRESS, 8)
kpi(T, "Bank", "Capital adequacy ratio", 16.85, "%", "Q1FY26", PRESS, 8)
kpi(T, "Bank", "CET-1 ratio", 14.64, "%", "Q1FY27", PRESS, 1)
kpi(T, "Bank", "Tier I ratio", 15.35, "%", "Q1FY27", PRESS, 8)
kpi(T, "Bank", "Tier I ratio", 15.10, "%", "Q1FY26", PRESS, 8)

df = pd.DataFrame(rows)
df.insert(0, "kpi_id", [f"K{i + 1:03d}" for i in range(len(df))])
save(df, "05_kpis_by_customer_segment.csv")
chk.report()
