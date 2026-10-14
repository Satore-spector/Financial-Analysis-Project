"""
OPTIONAL. Shows how the numbers were read out of the PDFs.

The three Axis Bank PDFs are scanned images with no text layer, so they were converted
to images and read with OCR (optical character recognition). The numbers were then typed
into the build scripts and checked two ways: against the page images by eye, and by the
reconciliation checks in each script (parts must add up to the printed totals).

You do NOT need to run this to rebuild the CSVs. Use it only to see the raw text.

Requirements (not plain pip):
    pip install pdf2image pytesseract
    Poppler    (Windows: download the poppler zip, add its bin folder to PATH)
    Tesseract  (Windows: install from the UB Mannheim build, add to PATH)

Run:
    python extract_pdf_text.py
Output: a "PDF Text" folder in Finlytics Project with one .txt file per PDF page.
"""

from pdf2image import convert_from_path
import pytesseract
from common import PROJECT_DIR

PDFS = [
    "Axis Bank Data file 1.pdf",
    "Axis Bank Press release for additional metrics.pdf",
    "Axis Bank earnings call Conference Data.pdf",
]

out_dir = PROJECT_DIR / "PDF Text"
out_dir.mkdir(exist_ok=True)

for name in PDFS:
    pdf_path = PROJECT_DIR / name
    pages = convert_from_path(str(pdf_path), dpi=250)      # higher DPI = better OCR on small table digits
    for number, image in enumerate(pages, start=1):
        text = pytesseract.image_to_string(image, config="--psm 6")   # psm 6 = treat page as a block of text
        target = out_dir / f"{pdf_path.stem} - page {number}.txt"
        target.write_text(text, encoding="utf-8")
    print(f"{name}: {len(pages)} pages extracted")

print(f"Text saved in: {out_dir}")
