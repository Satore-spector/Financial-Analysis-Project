"""
Builds:
    06_ratios.csv   65 presentation ratios, Q1FY27 vs Q1FY26

Needs: 01_segment_profitability.csv (run 01_segment_profitability.py first)

Sources:
    Axis Bank Data file 1.pdf (P&L p1, balance sheet p2, segments p5)
    Axis Bank Press release for additional metrics.pdf (p1, p2, p7, p8)
    Axis Bank earnings call Conference Data.pdf (p6, p7)

type = "Reported" means the bank printed the ratio; "Calculated" means it is worked out here.
"(approx.)" ratios use quarter-end balances because average balances are not disclosed.
"""

import pandas as pd
from common import DATA_FILE, PRESS, CALL, load, save

rows = []


def ratio(group, name, formula, q1fy27, q1fy26, unit, kind, source, note=""):
    rows.append(dict(
        ratio_group=group, ratio=name, formula=formula,
        Q1FY27=None if q1fy27 is None else round(q1fy27, 2),
        Q1FY26=None if q1fy26 is None else round(q1fy26, 2),
        change=None if q1fy27 is None or q1fy26 is None else round(q1fy27 - q1fy26, 2),
        unit=unit, type=kind, source=source, note=note))


# ---------------------------------------------------------------------------
# INPUTS
# ---------------------------------------------------------------------------
# Balances, press release p8 (Jun-2026, Jun-2025)
LOANS_26, LOANS_25 = 1261557, 1059724
CORP_26, CORP_25 = 434392, 315892
SME_26, SME_25 = 151619, 120872
RETAIL_26, RETAIL_25 = 675546, 622960
DEP_26, DEP_25 = 1372936, 1161615
CASA_26, CASA_25 = 521698, 468166
SA_26, SA_25 = 348312, 305133
CA_26, CA_25 = 173386, 163033
TD_26, TD_25 = 851238, 693449
# Borrowings and investments, Data file p2
BORR_26, BORR_25 = 237316.59, 180970.81
INV_26, INV_25 = 438955.12, 360640.60
# P&L, Data file p1 (Q1FY27, Q1FY26)
INT_LOANS_27, INT_LOANS_26 = 26515.74, 24408.10
INT_INV_27, INT_INV_26 = 6698.42, 6142.95
INT_PAID_27, INT_PAID_26 = 19339.53, 17503.76
NII_27, NII_26 = 14646.10, 13559.75
OTHER_INC_27, OTHER_INC_26 = 6735.42, 7258.06
OPEX_27, OPEX_26 = 9722.42, 9302.65
OP_PROFIT_27, OP_PROFIT_26 = 11659.10, 11515.16
PROV_27, PROV_26 = 2222.54, 3947.66
PBT_27, PBT_26 = 9436.56, 7567.50
GNPA_27, GNPA_26 = 17124.33, 17764.66
NNPA_27, NNPA_26 = 5192.56, 5065.99
# Fees and operating revenue, press release p7
FEE_27, FEE_26 = 6156, 5746
OPREV_PR_27, OPREV_PR_26 = 21382, 20818
# Gross slippages by segment, earnings call p7
SLIP_RETAIL, SLIP_CBG, SLIP_WHOLESALE, SLIP_TOTAL = 5176, 266, 124, 5566
NET_SLIP_ADJ_RETAIL = 2614

P8 = PRESS + " p8"
P1_2 = DATA_FILE + " p1-2"

# ---------------------------------------------------------------------------
# CASA
# ---------------------------------------------------------------------------
G = "CASA"
ratio(G, "CASA ratio (month-end)", "CASA / total deposits", CASA_26 / DEP_26 * 100, CASA_25 / DEP_25 * 100, "%", "Calculated", P8)
ratio(G, "CASA ratio (quarterly average)", "Reported", 37, 38, "%", "Reported", P8)
ratio(G, "Savings ratio", "SA / total deposits", SA_26 / DEP_26 * 100, SA_25 / DEP_25 * 100, "%", "Calculated", P8)
ratio(G, "Current account ratio", "CA / total deposits", CA_26 / DEP_26 * 100, CA_25 / DEP_25 * 100, "%", "Calculated", P8)
ratio(G, "Savings share of CASA", "SA / CASA", SA_26 / CASA_26 * 100, SA_25 / CASA_25 * 100, "%", "Calculated", P8)
ratio(G, "Incremental CASA share", "Change in CASA / change in total deposits (YoY)",
      (CASA_26 - CASA_25) / (DEP_26 - DEP_25) * 100, None, "%", "Calculated", P8, "Share of new deposits that came as CASA")
ratio(G, "CASA growth minus term deposit growth", "CASA YoY growth - TD YoY growth",
      (CASA_26 / CASA_25 - 1) * 100 - (TD_26 / TD_25 - 1) * 100, None, "pp", "Calculated", P8)
ratio(G, "CASA to advances", "CASA / net advances", CASA_26 / LOANS_26 * 100, CASA_25 / LOANS_25 * 100, "%", "Calculated", P8,
      "Share of loans funded by low-cost deposits")

# ---------------------------------------------------------------------------
# LOANS
# ---------------------------------------------------------------------------
G = "Loans"
ratio(G, "Credit-deposit ratio", "Net advances / total deposits", LOANS_26 / DEP_26 * 100, LOANS_25 / DEP_25 * 100, "%", "Calculated", P8)
for name, now, before in [("Corporate", CORP_26, CORP_25), ("SME", SME_26, SME_25), ("Retail", RETAIL_26, RETAIL_25)]:
    ratio(G, f"{name} share of advances", f"{name} advances / net advances",
          now / LOANS_26 * 100, before / LOANS_25 * 100, "%", "Calculated", P8)
    ratio(G, f"{name} share of incremental loans", f"Change in {name} / change in net advances",
          (now - before) / (LOANS_26 - LOANS_25) * 100, None, "%", "Calculated", P8)

yield_27 = INT_LOANS_27 * 4 / LOANS_26 * 100
yield_26 = INT_LOANS_26 * 4 / LOANS_25 * 100
cof_27 = INT_PAID_27 * 4 / (DEP_26 + BORR_26) * 100
cof_26 = INT_PAID_26 * 4 / (DEP_25 + BORR_25) * 100
ratio(G, "Yield on advances (approx.)", "Interest on advances x4 / period-end advances", yield_27, yield_26, "%", "Calculated", P1_2,
      "Period-end denominator; true yield uses average balances")
ratio(G, "Yield on investments (approx.)", "Income on investments x4 / period-end investments",
      INT_INV_27 * 4 / INV_26 * 100, INT_INV_26 * 4 / INV_25 * 100, "%", "Calculated", P1_2, "Period-end denominator")
ratio(G, "Cost of funds (approx.)", "Interest expended x4 / (deposits + borrowings)", cof_27, cof_26, "%", "Calculated", P1_2,
      "Reported change is -35 bps; this proxy uses period-end balances")
ratio(G, "Loan spread (approx.)", "Yield on advances - cost of funds", yield_27 - cof_27, yield_26 - cof_26, "pp", "Calculated", P1_2)
ratio(G, "Net interest margin", "Reported", 3.46, 3.80, "%", "Reported", PRESS + " p2 / " + CALL + " p6",
      "Q1FY26 = 3.46 + 34 bps YoY decline; matches 3.80% reported in Q1FY26")

# ---------------------------------------------------------------------------
# CREDIT QUALITY (credit given)
# ---------------------------------------------------------------------------
G = "Credit quality"
CALL_P7_PR_P8 = CALL + " p7, " + P8
ratio(G, "Gross NPA ratio", "Reported", 1.28, 1.57, "%", "Reported", DATA_FILE + " p1")
ratio(G, "Net NPA ratio", "Reported", 0.39, 0.45, "%", "Reported", DATA_FILE + " p1")
ratio(G, "Provision coverage ratio", "1 - net NPA / gross NPA",
      (1 - NNPA_27 / GNPA_27) * 100, (1 - NNPA_26 / GNPA_26) * 100, "%", "Calculated", DATA_FILE + " p1")
ratio(G, "Provisions to loans (annualized, approx.)", "Provisions x4 / period-end advances",
      PROV_27 * 4 / LOANS_26 * 100, PROV_26 * 4 / LOANS_25 * 100, "%", "Calculated", DATA_FILE + " p1",
      "Includes all provisions; reported net credit cost is 0.63%")
ratio(G, "Net credit cost", "Reported", 0.63, 1.38, "%", "Reported", PRESS + " p2",
      "Q1FY26 = 0.63 + 75 bps (bank definition). Broker estimates on other definitions differ (e.g. 1.50%)")
ratio(G, "Retail share of gross slippages", "Retail slippages / total", SLIP_RETAIL / SLIP_TOTAL * 100, None, "%", "Calculated", CALL + " p7")
ratio(G, "Retail gross slippage ratio (annualized)", "Retail gross slippages x4 / retail advances",
      SLIP_RETAIL * 4 / RETAIL_26 * 100, None, "%", "Calculated", CALL_P7_PR_P8)
ratio(G, "CBG gross slippage ratio (annualized)", "CBG gross slippages x4 / SME advances",
      SLIP_CBG * 4 / SME_26 * 100, None, "%", "Calculated", CALL_P7_PR_P8, "Assumes CBG book is close to the SME book; approximation")
ratio(G, "Wholesale gross slippage ratio (annualized)", "Wholesale slippages x4 / corporate advances",
      SLIP_WHOLESALE * 4 / CORP_26 * 100, None, "%", "Calculated", CALL_P7_PR_P8)
ratio(G, "Retail net slippage ratio adj. for recoveries (annualized)", "Retail net slippages adj. x4 / retail advances",
      NET_SLIP_ADJ_RETAIL * 4 / RETAIL_26 * 100, None, "%", "Calculated", CALL_P7_PR_P8)
ratio(G, "Gross slippage ratio (bank)", "Reported", 1.79, 3.13, "%", "Reported", PRESS + " p2",
      "Q1FY26 = 1.79 + 134 bps; matches ~3.1% in Q1FY26 broker note")

# ---------------------------------------------------------------------------
# SEGMENT PROFITABILITY (customer profitability), from file 01
# ---------------------------------------------------------------------------
G = "Segment profitability"
seg = load("01_segment_profitability.csv")
seg = seg[seg["entity"] == "Standalone"].set_index(["segment", "period"])
for name in ["Retail Banking", "Digital Banking", "Other Retail Banking", "Corporate/Wholesale Banking", "Treasury"]:
    now, before = seg.loc[(name, "Q1FY27")], seg.loc[(name, "Q1FY26")]
    src = DATA_FILE + " p5"
    ratio(G, f"{name}: return on segment assets (annualized)", "PBT x4 / segment assets",
          now.annualized_pbt_to_segment_assets_pct, before.annualized_pbt_to_segment_assets_pct, "%", "Calculated", src)
    ratio(G, f"{name}: PBT margin", "PBT / segment revenue", now.pbt_margin_pct, before.pbt_margin_pct, "%", "Calculated", src)
    ratio(G, f"{name}: share of bank PBT", "Segment PBT / total PBT",
          now.share_of_entity_pbt_pct, before.share_of_entity_pbt_pct, "%", "Calculated", src)
    ratio(G, f"{name}: liabilities to assets", "Segment liabilities / segment assets",
          now.liabilities_to_assets_x, before.liabilities_to_assets_x, "x", "Calculated", src)
    ratio(G, f"{name}: contribution to PBT change (YoY)", "Change in segment PBT / change in bank PBT",
          (now.segment_pbt_cr - before.segment_pbt_cr) / (PBT_27 - PBT_26) * 100, None, "%", "Calculated", src)
ratio(G, "Retail: net funds provided as % of bank deposits", "(Retail liabilities - assets) / total deposits",
      seg.loc[("Retail Banking", "Q1FY27")].net_funding_position_cr / DEP_26 * 100,
      seg.loc[("Retail Banking", "Q1FY26")].net_funding_position_cr / DEP_25 * 100,
      "%", "Calculated", DATA_FILE + " p5, " + P8)

# ---------------------------------------------------------------------------
# BANK PROFITABILITY
# ---------------------------------------------------------------------------
G = "Bank profitability"
oprev_27, oprev_26 = NII_27 + OTHER_INC_27, NII_26 + OTHER_INC_26
ratio(G, "Cost-to-income ratio", "Opex / (NII + other income)", OPEX_27 / oprev_27 * 100, OPEX_26 / oprev_26 * 100,
      "%", "Calculated", DATA_FILE + " p1")
ratio(G, "Fee income share of operating revenue", "Fee income / operating revenue",
      FEE_27 / OPREV_PR_27 * 100, FEE_26 / OPREV_PR_26 * 100, "%", "Calculated", PRESS + " p7")
ratio(G, "NII share of operating revenue", "NII / operating revenue", NII_27 / oprev_27 * 100, NII_26 / oprev_26 * 100,
      "%", "Calculated", DATA_FILE + " p1")
ratio(G, "Provisions to operating profit", "Provisions / operating profit",
      PROV_27 / OP_PROFIT_27 * 100, PROV_26 / OP_PROFIT_26 * 100, "%", "Calculated", DATA_FILE + " p1")
ratio(G, "Return on assets (annualized)", "Reported", 1.51, 1.47, "%", "Reported", PRESS + " p7")
ratio(G, "Return on equity (annualized)", "Reported", 14.16, 13.14, "%", "Reported", PRESS + " p7")
ratio(G, "Cost to assets", "Reported", 2.20, 2.41, "%", "Reported", PRESS + " p1",
      "Q1FY26 = 2.20 + 21 bps (Q1FY27 release). Broker note on Q1FY26 shows 2.32%: likely restatement or "
      "different definition. Quote the 21 bps YoY decline, not the Q1FY26 level")
ratio(G, "Capital adequacy ratio", "Reported", 16.67, 16.85, "%", "Reported", DATA_FILE + " p1")

save(pd.DataFrame(rows), "06_ratios.csv")
