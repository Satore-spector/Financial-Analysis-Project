# ==========================================================
# Conclusion module: final section, short interpretation of the project
# Sourced by app.R AFTER bridge.R, drivers_kpis.R and segment_matrix.R.
# Every number is read from objects those modules already built from the
# CSVs (bridge_stats, kpi_data, seg_tab, sm_*), so it stays in sync with
# the charts. ASCII only: symbols are \u escapes.
# ==========================================================

cn_minus <- "\u2212"

conclusion_ui <- function() {
  # ---- Figures ----
  profit_up   <- bridge_stats$chg / bridge_stats$start * 100
  prov_share  <- bridge_stats$prov / bridge_stats$chg * 100
  pbt_chg_txt <- paste0(inr, comma(bridge_stats$chg, accuracy = 1))

  k <- function(name) kpi_data[kpi_data$ratio == name, ]
  nim <- k("Net interest margin"); yld <- k("Yield on advances (approx.)")
  cof <- k("Cost of funds (approx.)"); casa <- k("CASA ratio (month-end)")

  sm_val <- function(label) sm_rows[[which(sapply(sm_rows, `[[`, "label") == label)]]$vals
  retail_pbt_share <- seg_tab$pbt[seg_tab$seg == "Retail Banking"] / d_pbt_chg * 100
  retail_liab  <- sm_val("Share of bank liabilities")[2] * 100
  retail_slip  <- sm_val("Share of gross slippages")[2] * 100
  corp_margin  <- sm_val("PBT margin")[1] * 100
  digi_roa     <- sm_val("Return on segment assets (annualised)")[3] * 100

  tagList(
    # Block 1: headline findings
    div(class = "fade-item",
      h2(class = "section-heading", "Conclusion"),
      p(class = "lead",
        "Axis Bank's profit rose strongly in Q1 FY27, but the growth came mostly from a lower charge for bad loans. The earning power of its loans and the strength of its deposit base both weakened."),
      div(class = "stat-grid",
        stat_card(sprintf("+%.1f%%", profit_up), "Profit before tax grew",
                  sprintf("%.0f%% of the %s cr rise came from lower provisions, not from the core business.",
                          prov_share, pbt_chg_txt)),
        stat_card(sprintf("%s%.2f points", cn_minus, abs(nim$chg)), "Net interest margin narrowed",
                  sprintf("Loan yields fell %.2f points against a %.2f fall in funding cost. The CASA ratio slipped %.1f points to %.1f%%.",
                          abs(yld$chg), abs(cof$chg), abs(casa$chg), casa$now), warn = TRUE),
        stat_card(sprintf("%.0f%%", retail_pbt_share), "Retail's share of the profit increase",
                  sprintf("Retail holds %.1f%% of the bank's liabilities, but also %.1f%% of its gross slippages.",
                          retail_liab, retail_slip)),
        stat_card(sprintf("%.1f%%", corp_margin), "Best margin: Corporate/Wholesale",
                  sprintf("Digital Banking earns the best return on assets (%.2f%%).", digi_roa))
      )
    ),

    # Block 2: interpretation + limits
    div(class = "fade-item",
      div(class = "callout",
        h4("What it means for customer profitability"),
        p("A customer segment is profitable at Axis when three things work together: what its loans earn, what its bad loans cost, and how cheaply its deposits fund the bank. This quarter the cost of bad loans improved sharply, while loan earnings and cheap deposits both weakened. Retail customers are the base of the bank's funding and now of its profit growth, but they are also where almost all slippages arise, so their profitability depends on credit quality holding. Corporate customers earn the highest margin but use more funding than they supply, and the loan book is shifting towards them. The profit rise is real, but it leans on a lower credit charge that is less certain to repeat than interest or fee growth, while the pressures on margin and CASA continue.")
      ),
      h3(class = "sub-heading", style = "margin-top: 36px;", "Limits and what to watch"),
      p(class = "sub-note",
        "These are bank and segment totals from one quarter's disclosures, not individual customer records, so the analysis compares segments but cannot rank customers. Segment revenue includes internal transfer pricing, the yield and funding-cost figures are approximations from period-end balances, and the comparison is a single year-on-year step. The three things to watch next are whether the credit charge stays low, whether the CASA ratio stabilises, and whether retail slippages ease.")
    )
  )
}
