"""
Shared settings used by every script in this folder.

Folder layout expected:
    Finlytics Project/
        Scripts/        <- these scripts
        Clean Data/     <- CSV outputs are written here
        Axis Bank Data file 1.pdf
        Axis Bank Press release for additional metrics.pdf
        Axis Bank earnings call Conference Data.pdf
"""

from pathlib import Path
import pandas as pd

SCRIPTS_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPTS_DIR.parent
DATA_DIR = PROJECT_DIR / "Clean Data"
DATA_DIR.mkdir(exist_ok=True)

# Source documents (names written into every CSV so each number can be traced)
DATA_FILE = "Axis Bank Data file 1.pdf"                             # results, P&L, balance sheet, segments
PRESS = "Axis Bank Press release for additional metrics.pdf"        # press release
CALL = "Axis Bank earnings call Conference Data.pdf"                # earnings call transcript

# Reporting periods used in the results tables
PERIODS = ["Q1FY27", "Q4FY26", "Q1FY26", "FY26"]
PERIOD_END = {"Q1FY27": "2026-06-30", "Q4FY26": "2026-03-31", "Q1FY26": "2025-06-30", "FY26": "2026-03-31"}
PERIOD_TYPE = {"Q1FY27": "Quarter", "Q4FY26": "Quarter", "Q1FY26": "Quarter", "FY26": "Year"}
ANNUALIZE = {"Q1FY27": 4, "Q4FY26": 4, "Q1FY26": 4, "FY26": 1}     # quarter x4 = annual rate

# Balance-sheet dates, and which one goes with each reporting period
BS_DATES = ["2026-06-30", "2026-03-31", "2025-06-30"]
BS_FOR_PERIOD = {"Q1FY27": "2026-06-30", "Q4FY26": "2026-03-31", "Q1FY26": "2025-06-30", "FY26": "2026-03-31"}


class Checker:
    """Collects reconciliation checks (parts must add up to reported totals)."""

    def __init__(self, name):
        self.name = name
        self.failed = []
        self.count = 0

    def equal(self, label, calculated, reported, tol=0.02):
        self.count += 1
        if abs(calculated - reported) > tol:
            self.failed.append(f"{label}: calculated {calculated:,.2f} vs reported {reported:,.2f}")

    def report(self):
        if self.failed:
            print(f"[{self.name}] {len(self.failed)} of {self.count} checks FAILED:")
            for f in self.failed:
                print("   ", f)
        else:
            print(f"[{self.name}] all {self.count} checks passed")


def save(df, filename):
    """Write a CSV that opens cleanly in Excel (UTF-8 with BOM)."""
    path = DATA_DIR / filename
    df.to_csv(path, index=False, encoding="utf-8-sig")
    print(f"Saved {filename} ({len(df)} rows)")
    return path


def load(filename):
    """Read a CSV produced by an earlier script."""
    return pd.read_csv(DATA_DIR / filename)
