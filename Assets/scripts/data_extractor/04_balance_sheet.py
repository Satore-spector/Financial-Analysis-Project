"""
Builds:
    04_balance_sheet.csv   standalone and consolidated balance sheets at three dates

Source: Axis Bank Data file 1.pdf
    page 2 = standalone Statement of Assets and Liabilities
    page 7 = consolidated Statement of Assets and Liabilities
All amounts INR crore. Value lists follow: 30-Jun-2026, 31-Mar-2026, 30-Jun-2025.
"""

import pandas as pd
from common import DATA_FILE, BS_DATES, Checker, save

TOTAL_LIAB = "Total capital and liabilities"
TOTAL_ASSETS = "Total assets"

BALANCE_SHEETS = {
    "Standalone": (2, [
        ("Capital", [622.16, 621.63, 620.24]),
        ("Employees' stock options outstanding", [1346.47, 1342.16, 1124.42]),
        ("Reserves and surplus", [211071.23, 203572.63, 184175.16]),
        ("Deposits", [1372935.66, 1335833.97, 1161614.55]),
        ("Borrowings", [237316.59, 235270.61, 180970.81]),
        ("Other liabilities and provisions", [98674.06, 110208.88, 74802.50]),
        (TOTAL_LIAB, [1921966.17, 1886849.88, 1603307.68]),
        ("Cash and balances with RBI", [58656.77, 78627.36, 65606.06]),
        ("Balances with banks and money at call", [72159.51, 26275.32, 33716.05]),
        ("Investments", [438955.12, 445032.80, 360640.60]),
        ("Advances", [1261556.65, 1233569.88, 1059724.39]),
        ("Fixed assets", [6602.75, 6549.36, 6372.37]),
        ("Other assets", [84035.37, 96795.16, 77248.21]),
        (TOTAL_ASSETS, [1921966.17, 1886849.88, 1603307.68]),
    ]),
    "Consolidated": (7, [
        ("Capital", [622.16, 621.63, 620.24]),
        ("Employees' stock options outstanding", [1473.91, 1456.43, 1205.91]),
        ("Reserves and surplus", [220980.84, 212957.29, 192043.20]),
        ("Minority interest", [836.25, 798.19, 670.91]),
        ("Deposits", [1371173.07, 1333791.44, 1159584.25]),
        ("Borrowings", [285257.98, 280510.62, 219991.64]),
        ("Other liabilities and provisions", [105651.34, 115914.69, 79373.53]),
        (TOTAL_LIAB, [1985995.55, 1946050.29, 1653489.68]),
        ("Cash and balances with RBI", [58656.85, 78627.37, 65606.12]),
        ("Balances with banks and money at call", [76940.40, 30724.20, 36841.93]),
        ("Investments", [438796.54, 446422.18, 361540.85]),
        ("Advances", [1315862.99, 1282392.17, 1102649.20]),
        ("Fixed assets", [6814.93, 6756.03, 6577.09]),
        ("Other assets", [88634.60, 100839.10, 79985.25]),
        ("Goodwill on consolidation", [289.24, 289.24, 289.24]),
        (TOTAL_ASSETS, [1985995.55, 1946050.29, 1653489.68]),
    ]),
}

chk = Checker("04 balance sheet")
rows = []
for entity, (page, items) in BALANCE_SHEETS.items():
    names = [n for n, _ in items]
    values = dict(items)
    split = names.index(TOTAL_LIAB)
    liability_lines = names[:split]               # everything above the liabilities total
    asset_lines = names[split + 1:-1]             # everything between the two totals

    for j, date in enumerate(BS_DATES):
        chk.equal(f"{entity} liabilities {date}", sum(values[n][j] for n in liability_lines), values[TOTAL_LIAB][j], 0.05)
        chk.equal(f"{entity} assets {date}", sum(values[n][j] for n in asset_lines), values[TOTAL_ASSETS][j], 0.05)

    for name, (jun26, mar26, jun25) in items:
        side = "Capital & Liabilities" if names.index(name) <= split else "Assets"
        rows.append(dict(entity=entity, side=side, line_item=name,
                         jun_2026_cr=jun26, mar_2026_cr=mar26, jun_2025_cr=jun25,
                         yoy_growth_pct=round((jun26 / jun25 - 1) * 100, 2),
                         qoq_growth_pct=round((jun26 / mar26 - 1) * 100, 2),
                         source_file=DATA_FILE, source_page=page))

# Cross-check against the press release (p8), which rounds to whole crore
chk.equal("Deposits: press release vs balance sheet", 1372936, 1372935.66, 0.5)
chk.equal("Advances: press release vs balance sheet", 1261557, 1261556.65, 0.5)

save(pd.DataFrame(rows), "04_balance_sheet.csv")
chk.report()
