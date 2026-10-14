"""
Builds:
    00_data_dictionary.csv   what every file and column means, plus caveats
"""

import pandas as pd
from common import save

rows = []


def entry(file, column, description):
    rows.append(dict(file=file, column=column, description=description))


F = "01_segment_profitability.csv"
entry(F, "(file)", "CORE TABLE. Axis Bank segment-level revenue, profit before tax, assets and liabilities, standalone and consolidated, for Q1FY27, Q4FY26, Q1FY26 and FY26. One row per entity x period x segment. All INR values in crore.")
entry(F, "entity", "Standalone (Axis Bank only) or Consolidated (bank + subsidiaries). Use Standalone for bank customer profitability.")
entry(F, "period / period_type / period_end", "Reporting period. Q = quarter, FY26 = full year ended 31-Mar-2026.")
entry(F, "balance_sheet_date", "Date of the segment assets/liabilities used for that period (quarter-end; FY26 uses 31-Mar-2026).")
entry(F, "segment / parent_segment / is_subsegment", "Digital Banking and Other Retail Banking are sub-segments of Retail Banking. FILTER is_subsegment = FALSE before summing, or you will double count Retail.")
entry(F, "segment_revenue_cr", "Gross segment revenue INCLUDING inter-segment revenue (internal funds transfer pricing). Retail earns FTP credit for the deposits/CASA it raises; this is how CASA profitability shows up. Totals reconcile to income from operations only after deducting inter-segment revenue (see 01b).")
entry(F, "segment_pbt_cr", "Segment result after provisions and before tax.")
entry(F, "segment_assets_cr / segment_liabilities_cr", "Segment balance sheet at balance_sheet_date. Assets are mainly loans (credit given); liabilities are mainly deposits (CASA + term).")
entry(F, "net_funding_position_cr", "Derived: liabilities minus assets. Positive = segment is a net provider of funds to the bank (deposit-rich, e.g. Retail); negative = net user of funds (loan-heavy, e.g. Corporate, Treasury).")
entry(F, "pbt_margin_pct", "Derived: PBT / segment revenue x 100. Blank for Unallocated.")
entry(F, "annualized_pbt_to_segment_assets_pct", "Derived return on segment assets: PBT x 4 / period-end assets for quarters; PBT / Mar-26 assets for FY26. Uses period-end, not average, assets. Blank for Other Banking Business (fee-based, tiny asset base makes the ratio meaningless) and Unallocated.")
entry(F, "liabilities_to_assets_x", "Derived: liabilities / assets. Above 1 = deposit-funded surplus.")
entry(F, "share_of_entity_*_pct", "Derived: segment value / entity total for the same period. Revenue share uses gross segment revenue total (before inter-segment elimination).")
entry(F, "segment_revenue_yoy_pct / _qoq_pct, segment_pbt_yoy_pct / _qoq_pct", "Derived growth, filled only on Q1FY27 rows (vs Q1FY26 and Q4FY26).")

entry("01b_segment_totals_reconciliation.csv", "(file)", "Segment totals, inter-segment revenue elimination and capital, for reconciling 01 to the reported income statement and balance sheet.")

F = "02_loans_and_deposits.csv"
entry(F, "(file)", "Loans given (Corporate, SME, Retail) and deposits (Savings, Current, CASA, Term, CASA on average balance basis), Jun-2025 vs Jun-2026, INR crore. reported_yoy_growth_pct is the bank's rounded figure; yoy_growth_pct is recomputed from the amounts.")
entry(F, "share_of_category_*_pct", "Derived share of total loans or total month-end deposits. Blank for the QAB row, which is on a different (average) basis.")

entry("03_income_statement_standalone.csv", "(file)", "Standalone P&L line items for the four periods, INR crore, plus derived lines (is_derived = TRUE): NII, operating revenue, cost-to-income, provisions/operating profit, effective tax rate. Q4FY26 tax is negative (one-time tax reversal, see source note 11), so Q4FY26 net profit is inflated.")
entry("04_balance_sheet.csv", "(file)", "Standalone and consolidated statement of assets and liabilities at 30-Jun-2026, 31-Mar-2026, 30-Jun-2025, INR crore.")
entry("05_kpis_by_customer_segment.csv", "(file)", "Long-format KPIs from the press release and earnings call: margins, cost of funds, CASA growth (QAB = quarterly average balance, MEB = month-end balance), loan mix and product growth, credit cards, fees by segment, slippages by Retail/CBG/Wholesale, NPAs, capital. Filter on theme and customer_segment.")

F = "06_ratios.csv"
entry(F, "(file)", "65 ratios for the presentation, Q1FY27 vs Q1FY26, grouped into CASA, Loans, Credit quality, Segment profitability and Bank profitability.")
entry(F, "type", "Reported = printed by the bank. Calculated = worked out from the bank's figures. '(approx.)' in the name means quarter-end balances were used instead of averages.")
entry(F, "change", "Q1FY27 minus Q1FY26, in the ratio's own unit (percentage points for % ratios).")
entry(F, "note", "Four Q1FY26 values (NIM, net credit cost, gross slippage ratio, cost to assets) are back-calculated from the bank's reported YoY change. Cost to assets Q1FY26 conflicts with an outside source: quote only the 21 bps decline.")

F = "07_driver_breakdown.csv"
entry(F, "(file)", "Why profit changed, Q1FY26 to Q1FY27. Section 1: bank PBT bridge by P&L line. Section 2: NII split into volume and rate effects (approx.). Section 3: CFO's NIM bridge in bps. Section 4: segment revenue, implied cost and PBT change.")
entry(F, "impact_on_pbt_cr", "Effect on profit before tax, INR crore. Costs are sign-flipped: a cost increase shows as negative. In section 1 the start value plus all driver rows equals the end value (within INR 0.4 crore, due to rounded press-release figures).")
entry(F, "method", "Change = Q1FY27 minus Q1FY26. Volume effect = Q1FY26 interest x balance growth. Rate effect = actual change minus volume effect. Implied cost = segment revenue minus segment PBT.")

entry("ALL", "source_file / source_page", "Exact PDF and page each value came from, for citation.")
entry("ALL", "Validation", "All component lines reconcile to reported totals within INR 0.02 crore (segment revenue, PBT, assets, liabilities, P&L arithmetic, balance sheet totals, loan and deposit splits, slippage splits). Source PDFs were scanned images; values were OCR-read and visually verified against the page images.")
entry("ALL", "Scope limit", "These are bank-level and segment-level aggregates from Axis Bank's Q1FY27 disclosures. There are NO individual customer records in the source files.")

save(pd.DataFrame(rows), "00_data_dictionary.csv")
