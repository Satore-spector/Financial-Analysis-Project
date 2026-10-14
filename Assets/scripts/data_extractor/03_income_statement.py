"""
Builds:
    03_income_statement_standalone.csv   standalone P&L for four periods, plus derived lines

Source: Axis Bank Data file 1.pdf, page 1 (Unaudited Standalone Financial Results)
All amounts INR crore. Value lists follow: Q1FY27, Q4FY26, Q1FY26, FY26.
"""

import numpy as np
import pandas as pd
from common import DATA_FILE, PERIODS, Checker, save

# (line number as printed, line item, values)
PL = [
    ("1",   "Interest earned (total)",                          [33985.63, 32724.09, 31063.51, 127032.23]),
    ("1a",  "Interest/discount on advances/bills",              [26515.74, 25512.49, 24408.10, 99508.19]),
    ("1b",  "Income on investments",                            [6698.42, 6709.26, 6142.95, 25299.80]),
    ("1c",  "Interest on balances with RBI & inter-bank funds", [450.91, 289.00, 307.64, 1273.50]),
    ("1d",  "Other interest",                                   [320.56, 213.34, 204.82, 950.74]),
    ("2",   "Other income",                                     [6735.42, 6022.55, 7258.06, 26130.85]),
    ("3",   "Total income",                                     [40721.05, 38746.64, 38321.57, 153163.08]),
    ("4",   "Interest expended",                                [19339.53, 18266.91, 17503.76, 70984.19]),
    ("5",   "Operating expenses (total)",                       [9722.42, 10466.31, 9302.65, 39362.08]),
    ("5i",  "Employees cost",                                   [3058.00, 3114.75, 3261.75, 12265.92]),
    ("5ii", "Other operating expenses",                         [6664.42, 7351.56, 6040.90, 27096.16]),
    ("6",   "Total expenditure excl. provisions",               [29061.95, 28733.22, 26806.41, 110346.27]),
    ("7",   "Operating profit (pre-provision)",                 [11659.10, 10013.42, 11515.16, 42816.81]),
    ("8",   "Provisions and contingencies (net)",               [2222.54, 3522.21, 3947.66, 13262.83]),
    ("10",  "Profit before tax",                                [9436.56, 6491.21, 7567.50, 29553.98]),
    ("11",  "Tax expense",                                      [2322.64, -580.10, 1761.36, 5097.32]),
    ("14",  "Net profit",                                       [7113.92, 7071.31, 5806.14, 24456.66]),
]
P = {line: values for line, _, values in PL}

# Total income per the segment table (Data file p5); must equal P&L total income
SEGMENT_INCOME_FROM_OPERATIONS = [40721.05, 38746.64, 38321.57, 153163.08]

# ---------------------------------------------------------------------------
# CHECKS: the P&L arithmetic printed on the page
# ---------------------------------------------------------------------------
chk = Checker("03 income statement")
for i, p in enumerate(PERIODS):
    chk.equal(f"Interest earned {p}", P["1a"][i] + P["1b"][i] + P["1c"][i] + P["1d"][i], P["1"][i])
    chk.equal(f"Total income {p}", P["1"][i] + P["2"][i], P["3"][i])
    chk.equal(f"Opex {p}", P["5i"][i] + P["5ii"][i], P["5"][i])
    chk.equal(f"Total expenditure {p}", P["4"][i] + P["5"][i], P["6"][i])
    chk.equal(f"Operating profit {p}", P["3"][i] - P["6"][i], P["7"][i])
    chk.equal(f"PBT {p}", P["7"][i] - P["8"][i], P["10"][i])
    chk.equal(f"Net profit {p}", P["10"][i] - P["11"][i], P["14"][i])
    chk.equal(f"Total income = segment income {p}", P["3"][i], SEGMENT_INCOME_FROM_OPERATIONS[i])

# ---------------------------------------------------------------------------
# DERIVED LINES
# ---------------------------------------------------------------------------
nii = [P["1"][i] - P["4"][i] for i in range(4)]
op_revenue = [nii[i] + P["2"][i] for i in range(4)]
DERIVED = [
    ("D1", "Net interest income (derived: 1 - 4)", [round(x, 2) for x in nii]),
    ("D2", "Operating revenue (derived: NII + other income)", [round(x, 2) for x in op_revenue]),
    ("D3", "Cost-to-income ratio % (derived: opex / operating revenue)", [round(P["5"][i] / op_revenue[i] * 100, 2) for i in range(4)]),
    ("D4", "Provisions as % of operating profit (derived)", [round(P["8"][i] / P["7"][i] * 100, 2) for i in range(4)]),
    ("D5", "Effective tax rate % (derived)", [round(P["11"][i] / P["10"][i] * 100, 2) for i in range(4)]),
]

rows = []
for line, item, values in PL + DERIVED:
    is_derived = line.startswith("D")
    unit = "%" if line in ("D3", "D4", "D5") else "INR crore"
    rows.append(dict(line_no=line, line_item=item, unit=unit,
                     **{p: values[i] for i, p in enumerate(PERIODS)},
                     is_derived=is_derived, source_file=DATA_FILE, source_page=1))
df = pd.DataFrame(rows)

# Growth only for amounts (not ratios) with a positive base
df["yoy_growth_q1_pct"] = df.apply(
    lambda r: round((r.Q1FY27 / r.Q1FY26 - 1) * 100, 2) if r.unit == "INR crore" and r.Q1FY26 > 0 else np.nan, axis=1)
df["qoq_growth_pct"] = df.apply(
    lambda r: round((r.Q1FY27 / r.Q4FY26 - 1) * 100, 2) if r.unit == "INR crore" and r.Q4FY26 > 0 else np.nan, axis=1)

save(df, "03_income_statement_standalone.csv")
chk.report()
