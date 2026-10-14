"""
Builds:
    01_segment_profitability.csv           one row per entity x period x segment
    01b_segment_totals_reconciliation.csv  segment totals, inter-segment revenue, capital

Source: Axis Bank Data file 1.pdf
    page 5 = standalone Segmental Results
    page 9 = consolidated Segmental Results

All amounts INR crore. Revenue and PBT lists follow PERIODS order: Q1FY27, Q4FY26, Q1FY26, FY26.
Assets and liabilities lists follow BS_DATES order: 30-Jun-2026, 31-Mar-2026, 30-Jun-2025.
"""

import numpy as np
import pandas as pd
from common import (DATA_FILE, PERIODS, PERIOD_END, PERIOD_TYPE, ANNUALIZE, BS_DATES,
                    BS_FOR_PERIOD, Checker, save)

# Segments in the order the bank reports them. Digital and Other Retail are parts of Retail.
SEGMENTS = [("Treasury", None), ("Corporate/Wholesale Banking", None), ("Retail Banking", None),
            ("Digital Banking", "Retail Banking"), ("Other Retail Banking", "Retail Banking"),
            ("Other Banking Business", None), ("Unallocated", None)]
TOP_LEVEL = [s for s, parent in SEGMENTS if parent is None]

# ---------------------------------------------------------------------------
# INPUTS copied from the Segmental Results tables
# ---------------------------------------------------------------------------
SEGMENT_DATA = {
    "Standalone": dict(
        page=5,
        revenue={
            "Treasury": [8487.17, 7015.71, 8419.72, 30409.97],
            "Corporate/Wholesale Banking": [14167.50, 12913.54, 11806.71, 49329.20],
            "Retail Banking": [38269.30, 36865.29, 35631.60, 145093.82],
            "Digital Banking": [10627.32, 10302.66, 9405.36, 39655.73],
            "Other Retail Banking": [27641.98, 26562.63, 26226.24, 105438.09],
            "Other Banking Business": [915.57, 1595.43, 1036.21, 4908.03],
            "Unallocated": [0.00, 9.61, 21.26, 63.57]},
        revenue_total=[61839.54, 58399.58, 56915.50, 229804.59],
        inter_segment=[21118.49, 19652.94, 18593.93, 76641.51],
        income_from_operations=[40721.05, 38746.64, 38321.57, 153163.08],
        pbt={
            "Treasury": [1663.85, 303.32, 2423.32, 5036.68],
            "Corporate/Wholesale Banking": [3358.26, 2139.85, 2737.21, 11205.92],
            "Retail Banking": [3565.52, 2473.14, 1435.87, 8607.32],
            "Digital Banking": [1531.43, 1340.41, 576.45, 4255.03],
            "Other Retail Banking": [2034.09, 1132.73, 859.42, 4352.29],
            "Other Banking Business": [848.93, 1565.29, 949.84, 4640.49],
            "Unallocated": [0.00, 9.61, 21.26, 63.57]},
        pbt_total=[9436.56, 6491.21, 7567.50, 29553.98],
        assets={
            "Treasury": [626906.76, 619567.76, 510734.13],
            "Corporate/Wholesale Banking": [598488.96, 571029.14, 447232.12],
            "Retail Banking": [686713.79, 686599.21, 637810.14],
            "Digital Banking": [153578.30, 148123.32, 131588.55],
            "Other Retail Banking": [533135.49, 538475.89, 506221.59],
            "Other Banking Business": [1064.84, 1084.10, 761.58],
            "Unallocated": [8791.82, 8569.67, 6769.71]},
        assets_total=[1921966.17, 1886849.88, 1603307.68],
        liabilities={
            "Treasury": [332810.15, 342691.86, 264326.67],
            "Corporate/Wholesale Banking": [237696.61, 254472.26, 219843.64],
            "Retail Banking": [1131328.33, 1077946.76, 925882.23],
            "Digital Banking": [230504.61, 219472.46, 189640.63],
            "Other Retail Banking": [900823.72, 858474.30, 736241.60],
            "Other Banking Business": [37.07, 48.50, 64.10],
            "Unallocated": [8400.62, 7496.24, 8395.64]},
        liabilities_total=[1710272.78, 1682655.62, 1418512.28],
        capital=[211693.39, 204194.26, 184795.40]),
    "Consolidated": dict(
        page=9,
        revenue={
            "Treasury": [9291.74, 7761.53, 9113.55, 33271.81],
            "Corporate/Wholesale Banking": [15026.97, 13718.13, 12520.78, 52500.54],
            "Retail Banking": [39517.11, 38077.25, 36618.39, 149401.52],
            "Digital Banking": [10627.32, 10302.66, 9405.36, 39655.73],
            "Other Retail Banking": [28889.79, 27774.59, 27213.03, 109745.79],
            "Other Banking Business": [1256.85, 1935.95, 1367.89, 6332.84],
            "Unallocated": [0.00, 9.61, 21.26, 63.57]},
        revenue_total=[65092.67, 61502.47, 59641.87, 241570.28],
        inter_segment=[21879.85, 20359.78, 19240.87, 79358.33],
        income_from_operations=[43212.82, 41142.69, 40401.00, 162211.95],
        pbt={
            "Treasury": [1690.16, 315.20, 2430.58, 5064.54],
            "Corporate/Wholesale Banking": [3601.14, 2353.18, 2958.75, 12175.71],
            "Retail Banking": [3851.40, 2816.46, 1647.83, 9578.58],
            "Digital Banking": [1531.43, 1340.41, 576.45, 4255.03],
            "Other Retail Banking": [2319.97, 1476.05, 1071.38, 5323.55],
            "Other Banking Business": [1018.58, 1752.74, 1121.28, 5411.07],
            "Unallocated": [0.00, 9.61, 21.26, 63.57]},
        pbt_total=[10161.28, 7247.19, 8179.70, 32293.47],
        assets={
            "Treasury": [622794.23, 616649.52, 508072.12],
            "Corporate/Wholesale Banking": [624360.42, 594824.55, 468434.17],
            "Retail Banking": [725645.64, 721709.71, 666739.71],
            "Digital Banking": [153578.30, 148123.32, 131588.55],
            "Other Retail Banking": [572067.34, 573586.39, 535151.16],
            "Other Banking Business": [4213.53, 4113.02, 3310.55],
            "Unallocated": [8981.73, 8753.49, 6933.13]},
        assets_total=[1985995.55, 1946050.29, 1653489.68],
        liabilities={
            "Treasury": [374055.94, 382781.74, 299207.91],
            "Corporate/Wholesale Banking": [240436.67, 256187.38, 220579.40],
            "Retail Banking": [1140341.33, 1084866.36, 931663.09],
            "Digital Banking": [230504.61, 219472.46, 189640.63],
            "Other Retail Banking": [909836.72, 865393.90, 742022.46],
            "Other Banking Business": [190.65, 223.21, 213.23],
            "Unallocated": [9367.96, 8412.68, 9162.61]},
        liabilities_total=[1764392.55, 1732471.37, 1460826.24],
        capital=[221603.00, 213578.92, 192663.44]),
}

# ---------------------------------------------------------------------------
# CHECKS: every breakdown must add up to the bank's printed total
# ---------------------------------------------------------------------------
chk = Checker("01 segments")
for entity, d in SEGMENT_DATA.items():
    for i, p in enumerate(PERIODS):
        chk.equal(f"{entity} revenue total {p}", sum(d["revenue"][s][i] for s in TOP_LEVEL), d["revenue_total"][i])
        chk.equal(f"{entity} retail revenue split {p}",
                  d["revenue"]["Digital Banking"][i] + d["revenue"]["Other Retail Banking"][i], d["revenue"]["Retail Banking"][i])
        chk.equal(f"{entity} income from operations {p}", d["revenue_total"][i] - d["inter_segment"][i], d["income_from_operations"][i])
        chk.equal(f"{entity} PBT total {p}", sum(d["pbt"][s][i] for s in TOP_LEVEL), d["pbt_total"][i])
        chk.equal(f"{entity} retail PBT split {p}",
                  d["pbt"]["Digital Banking"][i] + d["pbt"]["Other Retail Banking"][i], d["pbt"]["Retail Banking"][i])
    for j, date in enumerate(BS_DATES):
        chk.equal(f"{entity} assets total {date}", sum(d["assets"][s][j] for s in TOP_LEVEL), d["assets_total"][j])
        chk.equal(f"{entity} liabilities total {date}", sum(d["liabilities"][s][j] for s in TOP_LEVEL), d["liabilities_total"][j])
        chk.equal(f"{entity} balance sheet balances {date}", d["liabilities_total"][j] + d["capital"][j], d["assets_total"][j])
        chk.equal(f"{entity} retail assets split {date}",
                  d["assets"]["Digital Banking"][j] + d["assets"]["Other Retail Banking"][j], d["assets"]["Retail Banking"][j])
        chk.equal(f"{entity} retail liabilities split {date}",
                  d["liabilities"]["Digital Banking"][j] + d["liabilities"]["Other Retail Banking"][j], d["liabilities"]["Retail Banking"][j])

# ---------------------------------------------------------------------------
# BUILD 01: one row per entity x period x segment, with derived ratios
# ---------------------------------------------------------------------------
rows = []
for entity, d in SEGMENT_DATA.items():
    for i, p in enumerate(PERIODS):
        j = BS_DATES.index(BS_FOR_PERIOD[p])
        for seg, parent in SEGMENTS:
            rev, pbt = d["revenue"][seg][i], d["pbt"][seg][i]
            assets, liab = d["assets"][seg][j], d["liabilities"][seg][j]
            rows.append(dict(
                entity=entity, period=p, period_type=PERIOD_TYPE[p], period_end=PERIOD_END[p],
                balance_sheet_date=BS_FOR_PERIOD[p], segment=seg, parent_segment=parent or "",
                is_subsegment=parent is not None,
                segment_revenue_cr=rev, segment_pbt_cr=pbt,
                segment_assets_cr=assets, segment_liabilities_cr=liab,
                # positive = segment raises more deposits than it lends (net funds provider)
                net_funding_position_cr=round(liab - assets, 2),
                pbt_margin_pct=round(pbt / rev * 100, 2) if rev and seg != "Unallocated" else np.nan,
                # left blank where the asset base is too small to be meaningful
                annualized_pbt_to_segment_assets_pct=(round(pbt * ANNUALIZE[p] / assets * 100, 2)
                                                      if seg not in ("Other Banking Business", "Unallocated") else np.nan),
                liabilities_to_assets_x=round(liab / assets, 2),
                share_of_entity_pbt_pct=round(pbt / d["pbt_total"][i] * 100, 2),
                share_of_entity_revenue_pct=round(rev / d["revenue_total"][i] * 100, 2),
                share_of_entity_assets_pct=round(assets / d["assets_total"][j] * 100, 2),
                share_of_entity_liabilities_pct=round(liab / d["liabilities_total"][j] * 100, 2),
                source_file=DATA_FILE, source_page=d["page"]))
seg_df = pd.DataFrame(rows)

# Growth columns, filled only on Q1FY27 rows (YoY vs Q1FY26, QoQ vs Q4FY26)
for col in ["segment_revenue_cr", "segment_pbt_cr"]:
    lookup = seg_df.set_index(["entity", "segment", "period"])[col]

    def growth(row, base_period):
        base = lookup[(row.entity, row.segment, base_period)]
        if row.period != "Q1FY27" or row.segment == "Unallocated" or not base:
            return np.nan
        return round((lookup[(row.entity, row.segment, "Q1FY27")] / base - 1) * 100, 2)

    seg_df[col.replace("_cr", "_yoy_pct")] = seg_df.apply(growth, axis=1, base_period="Q1FY26")
    seg_df[col.replace("_cr", "_qoq_pct")] = seg_df.apply(growth, axis=1, base_period="Q4FY26")

save(seg_df, "01_segment_profitability.csv")

# ---------------------------------------------------------------------------
# BUILD 01b: totals for reconciling to the reported P&L and balance sheet
# ---------------------------------------------------------------------------
totals = []
for entity, d in SEGMENT_DATA.items():
    for i, p in enumerate(PERIODS):
        j = BS_DATES.index(BS_FOR_PERIOD[p])
        totals.append(dict(
            entity=entity, period=p,
            total_segment_revenue_cr=d["revenue_total"][i],
            less_inter_segment_revenue_cr=d["inter_segment"][i],
            income_from_operations_cr=d["income_from_operations"][i],
            total_pbt_cr=d["pbt_total"][i],
            total_assets_cr=d["assets_total"][j],
            total_segment_liabilities_cr=d["liabilities_total"][j],
            capital_and_reserves_cr=d["capital"][j],
            source_file=DATA_FILE, source_page=d["page"]))
save(pd.DataFrame(totals), "01b_segment_totals_reconciliation.csv")

chk.report()
