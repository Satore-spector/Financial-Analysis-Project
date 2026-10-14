"""
Rebuilds every CSV in the Clean Data folder, in the right order.

    python run_all.py

Order matters: 06 and 07 read the output of 01.
"""

import runpy
from common import SCRIPTS_DIR, DATA_DIR

ORDER = [
    "01_segment_profitability.py",
    "02_loans_and_deposits.py",
    "03_income_statement.py",
    "04_balance_sheet.py",
    "05_kpis.py",
    "06_ratios.py",
    "07_driver_breakdown.py",
    "00_data_dictionary.py",
]

for script in ORDER:
    print(f"\n=== {script} ===")
    runpy.run_path(str(SCRIPTS_DIR / script), run_name="__main__")

print(f"\nDone. All files written to: {DATA_DIR}")
