"""
Builds:
    02_loans_and_deposits.csv   loans by customer segment and deposits (CASA, term), Jun-2025 vs Jun-2026

Source: Axis Bank Press release for additional metrics.pdf, page 8 (Business Performance table)
All amounts INR crore, as printed (rounded to whole crore by the bank).
"""

import numpy as np
import pandas as pd
from common import PRESS, Checker, save

# (category, customer segment, line item, 30-Jun-2026, 30-Jun-2025, bank's reported YoY growth %)
ITEMS = [
    ("Loans", "Total", "Net Advances (total)", 1261557, 1059724, 19),
    ("Loans", "Corporate", "Corporate advances", 434392, 315892, 38),
    ("Loans", "SME", "SME advances", 151619, 120872, 25),
    ("Loans", "Retail", "Retail advances", 675546, 622960, 8),
    ("Deposits", "Total", "Total Deposits (month-end)", 1372936, 1161615, 18),
    ("Deposits", "CASA", "CASA deposits (month-end)", 521698, 468166, 11),
    ("Deposits", "CASA", "Savings Bank deposits (month-end)", 348312, 305133, 14),
    ("Deposits", "CASA", "Current Account deposits (month-end)", 173386, 163033, 6),
    ("Deposits", "Term", "Term deposits (month-end)", 851238, 693449, 23),
    ("Deposits", "CASA", "CASA deposits (quarterly daily average, QAB)", 481452, 424272, 13),
    ("Investments", "Treasury", "Investments", 438955, 360641, 22),
    ("Balance sheet", "Total", "Balance sheet size", 1921966, 1603308, 20),
]

TOTALS = {("Loans", 2026): 1261557, ("Loans", 2025): 1059724,
          ("Deposits", 2026): 1372936, ("Deposits", 2025): 1161615}

# ---------------------------------------------------------------------------
# CHECKS: splits add up (tolerance INR 1.5 crore for the bank's rounding),
# and recomputed growth matches the bank's rounded growth
# ---------------------------------------------------------------------------
chk = Checker("02 loans and deposits")
chk.equal("Loans Jun-26", 434392 + 151619 + 675546, 1261557, 1.5)
chk.equal("Loans Jun-25", 315892 + 120872 + 622960, 1059724, 1.5)
chk.equal("Deposits Jun-26", 521698 + 851238, 1372936, 1.5)
chk.equal("Deposits Jun-25", 468166 + 693449, 1161615, 1.5)
chk.equal("CASA Jun-26", 348312 + 173386, 521698, 1.5)
chk.equal("CASA Jun-25", 305133 + 163033, 468166, 1.5)

rows = []
for category, segment, item, jun26, jun25, reported in ITEMS:
    growth = round((jun26 / jun25 - 1) * 100, 2)
    chk.equal(f"Growth {item}", growth, reported, 0.6)
    in_mix = category in ("Loans", "Deposits") and "QAB" not in item   # QAB row is an average, not part of the mix
    rows.append(dict(
        category=category, customer_segment=segment, line_item=item,
        jun_2025_cr=jun25, jun_2026_cr=jun26, abs_change_cr=jun26 - jun25,
        yoy_growth_pct=growth, reported_yoy_growth_pct=reported,
        source_file=PRESS, source_page=8,
        share_of_category_jun_2026_pct=round(jun26 / TOTALS[(category, 2026)] * 100, 2) if in_mix else np.nan,
        share_of_category_jun_2025_pct=round(jun25 / TOTALS[(category, 2025)] * 100, 2) if in_mix else np.nan))

save(pd.DataFrame(rows), "02_loans_and_deposits.csv")
chk.report()
