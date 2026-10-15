"""
Driver breakdown for Axis Bank (standalone), Q1FY26 vs Q1FY27
Finlytics project: Customer profitability based on loans given, credit given and CASA deposits

What this script does
  Part 1  Bank profit bridge: how each P&L line moved profit before tax (PBT)
  Part 2  Net interest income split into volume effect (more loans/deposits) and rate effect
  Part 3  Management's NIM bridge, copied from the earnings call
  Part 4  Segment bridge: revenue change, implied cost change and PBT change per segment

Needs: 01_segment_profitability.csv (run 01_segment_profitability.py first)
Output: 07_driver_breakdown.csv in the Clean Data folder.

All amounts are INR crore. Every input number is typed in below with the PDF and page it came from.
"""

import pandas as pd
from common import load, save

# Source labels (written into the output so every number can be traced)
DATA_P1 = "Axis Bank Data file 1.pdf p1"                        # standalone P&L
DATA_P2 = "Axis Bank Data file 1.pdf p2"                        # standalone balance sheet
DATA_P5 = "Axis Bank Data file 1.pdf p5"                        # segment results
PR_P7   = "Axis Bank Press release for additional metrics.pdf p7"  # other income split
PR_P8   = "Axis Bank Press release for additional metrics.pdf p8"  # loans and deposits
CALL_P6 = "Axis Bank earnings call Conference Data.pdf p6"      # CFO's NIM bridge

rows = []


def add(level, section, driver, q1fy26, q1fy27, impact, method, source, note=""):
    """Append one row to the output table."""
    rows.append({
        "level": level,
        "section": section,
        "driver": driver,
        "Q1FY26": None if q1fy26 is None else round(q1fy26, 2),
        "Q1FY27": None if q1fy27 is None else round(q1fy27, 2),
        "impact_on_pbt_cr": None if impact is None else round(impact, 2),
        "method": method,
        "source": source,
        "note": note,
    })


# ---------------------------------------------------------------------------
# INPUTS (copied from the PDFs)
# ---------------------------------------------------------------------------
# P&L, Data file p1
interest_earned   = {"Q1FY26": 31063.51, "Q1FY27": 33985.63}
interest_on_loans = {"Q1FY26": 24408.10, "Q1FY27": 26515.74}
interest_paid     = {"Q1FY26": 17503.76, "Q1FY27": 19339.53}
opex              = {"Q1FY26":  9302.65, "Q1FY27":  9722.42}
provisions        = {"Q1FY26":  3947.66, "Q1FY27":  2222.54}
pbt               = {"Q1FY26":  7567.50, "Q1FY27":  9436.56}

# Other income split, Press release p7 (rounded to whole crore by the bank)
fee_income     = {"Q1FY26": 5746, "Q1FY27": 6156}
trading_income = {"Q1FY26": 1420, "Q1FY27":  537}
misc_income    = {"Q1FY26":   92, "Q1FY27":   42}

# Balances at quarter end: loans from Press release p8; deposits and borrowings from Data file p2
loans       = {"Q1FY26": 1059724,    "Q1FY27": 1261557}
deposits    = {"Q1FY26": 1161614.55, "Q1FY27": 1372935.66}
borrowings  = {"Q1FY26":  180970.81, "Q1FY27":  237316.59}


def change(d):
    return d["Q1FY27"] - d["Q1FY26"]


# ---------------------------------------------------------------------------
# PART 1: Bank profit bridge
# Idea: PBT = NII + other income - opex - provisions.
# Each line's change, with the right sign, explains the change in PBT.
# ---------------------------------------------------------------------------
nii = {k: interest_earned[k] - interest_paid[k] for k in interest_earned}

S1 = "1. PBT bridge"
add("Bank", S1, "Start: PBT Q1FY26", None, None, pbt["Q1FY26"], "Reported", DATA_P1)
add("Bank", S1, "Net interest income", nii["Q1FY26"], nii["Q1FY27"], change(nii),
    "Change (interest earned - interest paid)", DATA_P1)
add("Bank", S1, "Fee income", fee_income["Q1FY26"], fee_income["Q1FY27"], change(fee_income), "Change", PR_P7)
add("Bank", S1, "Trading income", trading_income["Q1FY26"], trading_income["Q1FY27"], change(trading_income),
    "Change", PR_P7, "Q1FY26 had large bond gains")
add("Bank", S1, "Miscellaneous income", misc_income["Q1FY26"], misc_income["Q1FY27"], change(misc_income), "Change", PR_P7)
add("Bank", S1, "Operating expenses", opex["Q1FY26"], opex["Q1FY27"], -change(opex),
    "Change (higher cost reduces PBT, so sign is flipped)", DATA_P1)
add("Bank", S1, "Provisions", provisions["Q1FY26"], provisions["Q1FY27"], -change(provisions),
    "Change (lower provisions raise PBT, so sign is flipped)", DATA_P1)
add("Bank", S1, "End: PBT Q1FY27", None, None, pbt["Q1FY27"], "Reported", DATA_P1,
    "Other income lines are rounded by the bank, so the bridge closes within INR 1 crore")

# ---------------------------------------------------------------------------
# PART 2: Net interest income, volume vs rate (approximate)
# Idea: interest = balance x rate.
#   Volume effect = last year's interest x growth in balance  (what growth alone would add)
#   Rate effect   = actual change - volume effect             (what rate changes added or removed)
# Uses quarter-end balances because average balances are not disclosed.
# ---------------------------------------------------------------------------
funding = {k: deposits[k] + borrowings[k] for k in deposits}

loan_growth = loans["Q1FY27"] / loans["Q1FY26"] - 1
funding_growth = funding["Q1FY27"] / funding["Q1FY26"] - 1

loans_volume = interest_on_loans["Q1FY26"] * loan_growth
loans_rate = change(interest_on_loans) - loans_volume

paid_volume = interest_paid["Q1FY26"] * funding_growth
paid_rate = change(interest_paid) - paid_volume

other_interest = {k: interest_earned[k] - interest_on_loans[k] for k in interest_earned}

S2 = "2. NII volume vs rate"
add("Bank", S2, "Interest on loans: volume effect (loan growth)",
    interest_on_loans["Q1FY26"], interest_on_loans["Q1FY27"], loans_volume,
    f"Q1FY26 interest x loan growth ({loan_growth:.1%})", DATA_P1, "Approx: quarter-end balances")
add("Bank", S2, "Interest on loans: rate effect (lower yields)", None, None, loans_rate,
    "Actual change - volume effect", DATA_P1, "Repo rate cuts passed through to loan rates")
add("Bank", S2, "Interest paid: volume effect (more deposits and borrowings)",
    interest_paid["Q1FY26"], interest_paid["Q1FY27"], -paid_volume,
    f"Q1FY26 interest paid x funding growth ({funding_growth:.1%})", DATA_P2, "Approx: quarter-end balances")
add("Bank", S2, "Interest paid: rate effect (lower cost of funds)", None, None, -paid_rate,
    "Actual change - volume effect", DATA_P1)
add("Bank", S2, "Other interest income (investments, RBI balances)",
    other_interest["Q1FY26"], other_interest["Q1FY27"], change(other_interest), "Change", DATA_P1)

# ---------------------------------------------------------------------------
# PART 3: NIM bridge as explained by the CFO (no calculation, copied)
# ---------------------------------------------------------------------------
S3 = "3. NIM bridge (management, bps)"
for driver, bps, note in [
    ("NIM YoY change (total)", -34, "3.80% to 3.46%"),
    ("  due to repo rate cuts net of deposit repricing", -19, ""),
    ("  due to balance sheet mix", -16, "more corporate, less retail lending"),
    ("NIM QoQ change (total)", -16, ""),
    ("  due to agri slippage interest reversal (seasonal)", -3, ""),
    ("  due to balance sheet mix", -4, ""),
    ("  due to loan pricing", -9, ""),
]:
    add("Bank", S3, driver, None, bps, None, "Reported by CFO", CALL_P6, note)

# ---------------------------------------------------------------------------
# PART 4: Segment bridge
# Idea: revenue - PBT = all costs of the segment combined.
# So the change in costs can be worked out from revenue and PBT alone.
# ---------------------------------------------------------------------------
seg = load("01_segment_profitability.csv")
seg = seg[seg["entity"] == "Standalone"].set_index(["segment", "period"])

S4 = "4. Segment bridge"
for name in ["Retail Banking", "Digital Banking", "Other Retail Banking",
             "Corporate/Wholesale Banking", "Treasury", "Other Banking Business"]:
    rev_26 = seg.loc[(name, "Q1FY26"), "segment_revenue_cr"]
    rev_27 = seg.loc[(name, "Q1FY27"), "segment_revenue_cr"]
    pbt_26 = seg.loc[(name, "Q1FY26"), "segment_pbt_cr"]
    pbt_27 = seg.loc[(name, "Q1FY27"), "segment_pbt_cr"]
    cost_26, cost_27 = rev_26 - pbt_26, rev_27 - pbt_27

    add("Segment", S4, f"{name}: revenue change", rev_26, rev_27, rev_27 - rev_26, "Change", DATA_P5)
    add("Segment", S4, f"{name}: implied cost change (revenue - PBT)", cost_26, cost_27, -(cost_27 - cost_26),
        "Derived (higher cost reduces PBT)", DATA_P5,
        "All costs combined: internal funding charge, opex and provisions; not split in disclosures")
    add("Segment", S4, f"{name}: PBT change", pbt_26, pbt_27, pbt_27 - pbt_26, "Change", DATA_P5)

# ---------------------------------------------------------------------------
# CHECKS AND OUTPUT
# ---------------------------------------------------------------------------
out = pd.DataFrame(rows)

# Check 1: the PBT bridge should land on reported Q1FY27 PBT
bridge = out[out["section"] == S1]["impact_on_pbt_cr"].tolist()
bridge_end = bridge[0] + sum(bridge[1:-1])
print(f"Check 1  bridge ends at {bridge_end:,.2f} vs reported PBT {pbt['Q1FY27']:,.2f} "
      f"(gap {pbt['Q1FY27'] - bridge_end:,.2f}, from rounded press-release figures)")

# Check 2: the volume/rate parts should add up to the NII change
nii_parts = out[out["section"] == S2]["impact_on_pbt_cr"].sum()
print(f"Check 2  volume/rate parts add to {nii_parts:,.2f} vs NII change {change(nii):,.2f}")

save(out, "07_driver_breakdown.csv")
