# ==========================================================
# Segment comparison matrix module: heat map table + PBT margin trend
# Sourced by app.R AFTER modules/eda.R (reuses profit, recon, loans,
# kpis, pal, theme_axis, plot_font, inr). stat_card() comes from app.R
# and is only called when the UI is built. ASCII only: \u escapes.
#
# Mirrors sheet 6 (Segment_Matrix) and sheet 1 (PBT margin trend) of
# Axis_Bank_Key_Ratios_Q1FY27.xlsx, rebuilt from the cleaned CSVs.
# To change which segments appear, edit sm_segments / sm_heads below.
# ==========================================================

sm_minus <- "\u2212"

# ---- Segments shown (Other Banking Business is left out: a tiny,
# fee-only line with a ~93% margin that would distort every colour scale)
sm_segments <- c("Corporate/Wholesale Banking", "Retail Banking", "Digital Banking",
                 "Other Retail Banking", "Treasury")
sm_heads    <- c("Corporate / Wholesale", "Retail (total)", "Digital Banking",
                 "Other Retail", "Treasury")
sm_subhead  <- c("", "", "within Retail", "within Retail", "")

# ---- Inputs ----
sm_pick <- function(period) {
  d <- profit[profit$entity == "Standalone" & profit$period == period, ]
  d[match(sm_segments, d$segment), ]
}
sm_cur <- sm_pick("Q1FY27")   # current quarter
sm_prv <- sm_pick("Q1FY26")   # same quarter last year
sm_qoq <- sm_pick("Q4FY26")   # previous quarter (margin trend only)
stopifnot(!anyNA(sm_cur$segment), !anyNA(sm_prv$segment), !anyNA(sm_qoq$segment))

sm_tot <- function(period) recon[recon$entity == "Standalone" & recon$period == period, ]
sm_t27 <- sm_tot("Q1FY27"); sm_t26 <- sm_tot("Q1FY26")

sm_rev  <- sm_cur$segment_revenue_cr;  sm_pbt  <- sm_cur$segment_pbt_cr
sm_ast  <- sm_cur$segment_assets_cr;   sm_lia  <- sm_cur$segment_liabilities_cr
sm_rev0 <- sm_prv$segment_revenue_cr;  sm_pbt0 <- sm_prv$segment_pbt_cr

# Loans (Jun-26) and gross slippages (Q1 FY27). Corporate/Wholesale = Corporate +
# SME advances and Wholesale (WBCG) + CBG slippages. Not split for the other segments.
sm_adv_of <- function(buckets) sum(loans$jun_2026_cr[loans$category == "Loans" &
                                                      loans$customer_segment %in% buckets])
sm_slp_of <- function(buckets) sum(kpis$value[kpis$metric == "Gross slippages" &
                                              kpis$period == "Q1FY27" &
                                              kpis$customer_segment %in% buckets])
sm_adv <- c(sm_adv_of(c("Corporate", "SME")), sm_adv_of("Retail"), NA, NA, NA)
sm_slp <- c(sm_slp_of(c("Wholesale (WBCG)", "CBG")), sm_slp_of("Retail"), NA, NA, NA)
sm_adv_bank <- loans$jun_2026_cr[loans$line_item == "Net Advances (total)"]
sm_slp_bank <- sm_slp_of("Bank")

# ---- Metric rows: group, label, better ("higher"/"lower"/"-"), type, values ----
sm_row <- function(group, label, better, type, vals)
  list(group = group, label = label, better = better, type = type, vals = vals)

sm_rows <- list(
  sm_row("Profitability", "PBT margin",                             "higher", "pct1", sm_pbt / sm_rev),
  sm_row("Profitability", "Return on segment assets (annualised)",  "higher", "pct2", sm_pbt * 4 / sm_ast),
  sm_row("Growth",        "Revenue growth, year on year",           "higher", "pct1", sm_rev / sm_rev0 - 1),
  sm_row("Growth",        "PBT growth, year on year",               "higher", "pct1", sm_pbt / sm_pbt0 - 1),
  sm_row("Contribution",  "Share of bank revenue (gross)",          "-",      "pct1", sm_rev / sm_t27$total_segment_revenue_cr),
  sm_row("Contribution",  "Share of bank PBT",                      "-",      "pct1", sm_pbt / sm_t27$total_pbt_cr),
  sm_row("Contribution",  "Share of bank assets",                   "-",      "pct1", sm_ast / sm_t27$total_assets_cr),
  sm_row("Contribution",  "Share of bank liabilities",              "-",      "pct1", sm_lia / sm_t27$total_segment_liabilities_cr),
  sm_row("Funding",       "Liabilities to assets",                  "higher", "x",    sm_lia / sm_ast),
  sm_row("Funding",       "Net funding position",                   "-",      "cr",   sm_lia - sm_ast),
  sm_row("Credit risk",   "Share of loans (credit mix)",            "-",      "pct1", sm_adv / sm_adv_bank),
  sm_row("Credit risk",   "Share of gross slippages",               "lower",  "pct1", sm_slp / sm_slp_bank),
  sm_row("Credit risk",   "Gross slippage rate (annualised)",       "lower",  "pct2", sm_slp * 4 / sm_adv)
)

# ---- Formatting ----
sm_fmt <- function(v, type) {
  if (is.na(v)) return(NA_character_)
  switch(type,
    pct1 = paste0(ifelse(v < 0, sm_minus, ""), sprintf("%.1f", abs(v) * 100), "%"),
    pct2 = paste0(ifelse(v < 0, sm_minus, ""), sprintf("%.2f", abs(v) * 100), "%"),
    x    = sprintf("%.2fx", v),
    cr   = paste0(ifelse(v < 0, sm_minus, ""), inr,
                  if (abs(v) >= 100000) paste0(sprintf("%.2f", abs(v) / 100000), " lakh cr")
                  else paste0(comma(abs(v), accuracy = 1), " cr")))
}

# ---- Heat colours: pale rose (worst on the row) to burgundy (best) ----
sm_ramp <- grDevices::colorRamp(c("#F3E7EC", "#97144D"))
sm_scale <- function(vals, better) {
  ok <- !is.na(vals)
  if (better == "-" || sum(ok) < 2 || max(vals[ok]) == min(vals[ok])) return(rep(NA_real_, length(vals)))
  t <- (vals - min(vals[ok])) / (max(vals[ok]) - min(vals[ok]))
  if (better == "lower") t <- 1 - t
  t
}
sm_rank <- function(vals, better) {
  if (better == "-") return(rep(NA_integer_, length(vals)))
  r <- rank(if (better == "higher") -vals else vals, ties.method = "min", na.last = "keep")
  as.integer(r)
}

# d = animation delay in seconds (set per cell so the table fills in row by row)
sm_delay <- function(d) sprintf("--d:%.2fs;", d)

sm_cell <- function(v, type, t, rk, d = 0) {
  if (is.na(v)) return(tags$td(class = "mx-cell mx-na", style = sm_delay(d), "n/a"))
  if (is.na(t)) return(tags$td(class = "mx-cell", style = sm_delay(d),
                               div(class = "mx-val", sm_fmt(v, type))))
  rgbv <- round(sm_ramp(t))
  bg <- sprintf("rgb(%d,%d,%d)", rgbv[1], rgbv[2], rgbv[3])
  fg <- if (t >= 0.5) "#FFFFFF" else pal$text
  tags$td(class = "mx-cell", style = paste0("background:", bg, ";color:", fg, ";", sm_delay(d)),
    div(class = "mx-val", sm_fmt(v, type)),
    div(class = "mx-rank", paste0("#", rk))
  )
}

sm_dir <- function(better) switch(better,
  higher = "\u25B2 higher", lower = "\u25BC lower", "\u2013")

sm_table_ui <- function() {
  body <- list(); last_group <- ""; row_i <- 0
  for (r in sm_rows) {
    row_i <- row_i + 1
    row_d <- 0.15 + (row_i - 1) * 0.09     # each row starts a little after the one above
    if (r$group != last_group) {
      body[[length(body) + 1]] <- tags$tr(class = "mx-group",
        tags$td(colspan = length(sm_segments) + 2, r$group))
      last_group <- r$group
    }
    ts <- sm_scale(r$vals, r$better); rk <- sm_rank(r$vals, r$better)
    cells <- lapply(seq_along(sm_segments), function(i)
      sm_cell(r$vals[i], r$type, ts[i], rk[i], d = row_d + 0.12 + (i - 1) * 0.07))
    body[[length(body) + 1]] <- tags$tr(
      tags$td(class = "mx-cell mx-metric", style = sm_delay(row_d), r$label),
      tags$td(class = "mx-cell mx-dir", style = sm_delay(row_d), sm_dir(r$better)),
      cells
    )
  }
  head <- tags$tr(
    tags$th(class = "mx-metric", "Metric"), tags$th("Direction"),
    lapply(seq_along(sm_segments), function(i)
      tags$th(sm_heads[i], if (nzchar(sm_subhead[i])) div(class = "mx-sub", sm_subhead[i])))
  )
  div(class = "mx-wrap",
    tags$table(class = "mx-table", tags$thead(head), tags$tbody(body)))
}

# ---- Margin trend chart (sheet 1): PBT margin by quarter ----
plot_sm_margin <- function() {
  per <- c("Q1 FY26", "Q4 FY26", "Q1 FY27")
  d <- data.frame(
    seg = factor(rep(sm_heads, 3), levels = sm_heads),
    per = factor(rep(per, each = length(sm_segments)), levels = per),
    m   = c(sm_prv$segment_pbt_cr / sm_prv$segment_revenue_cr,
            sm_qoq$segment_pbt_cr / sm_qoq$segment_revenue_cr,
            sm_cur$segment_pbt_cr / sm_cur$segment_revenue_cr) * 100
  )
  d$lab <- sprintf("%.1f%%", d$m)
  dodge <- position_dodge(width = 0.8)
  ggplot(d, aes(x = seg, y = m, fill = per)) +
    geom_col(position = dodge, width = 0.72) +
    geom_text(aes(label = lab), position = dodge, vjust = -0.5,
              family = plot_font, size = 4.7, colour = pal$text) +
    scale_fill_manual(values = setNames(c(pal$rose, pal$muted, pal$primary), per)) +
    scale_y_continuous(labels = function(x) paste0(x, "%"), expand = expansion(mult = c(0, 0.12))) +
    labs(x = NULL, y = "PBT margin (% of gross segment revenue)") +
    theme_axis()
}

# Animated version (echarts4r): same grouped bars, they grow in segment by segment.
# Drawing code is shared in modules/echarts_helpers.R. The ggplot function above is
# kept for reference but is no longer shown.
plot_sm_margin_echarts <- function() {
  per <- c("Q1 FY26", "Q4 FY26", "Q1 FY27")
  d <- data.frame(
    x     = rep(sm_heads, 3),
    group = factor(rep(per, each = length(sm_segments)), levels = per),
    value = c(sm_prv$segment_pbt_cr / sm_prv$segment_revenue_cr,
              sm_qoq$segment_pbt_cr / sm_qoq$segment_revenue_cr,
              sm_cur$segment_pbt_cr / sm_cur$segment_revenue_cr) * 100
  )
  ec_bar_chart(
    x = sm_heads,
    series = ec_from_long(d, setNames(c(pal$rose, pal$muted, pal$primary), per),
                          function(v) sprintf("%.1f%%", v)),
    y_title = "PBT margin (% of gross segment revenue)",
    value_suffix = "%"
  )
}

# ---------------------------------------------------------
# Section content (three fading blocks)
# ---------------------------------------------------------
segment_matrix_ui <- function() {
  vals <- function(label) sm_rows[[which(sapply(sm_rows, `[[`, "label") == label)]]$vals
  best <- function(v) which.max(v)
  nm <- function(i) sm_heads[i]
  pct <- function(x, d = 1) sprintf(paste0("%.", d, "f%%"), x * 100)

  margin <- vals("PBT margin"); roa <- vals("Return on segment assets (annualised)")
  pbtg <- vals("PBT growth, year on year"); slr <- vals("Gross slippage rate (annualised)")
  la <- vals("Liabilities to assets")
  s_rev <- vals("Share of bank revenue (gross)")[2]; s_lia <- vals("Share of bank liabilities")[2]
  s_slp <- vals("Share of gross slippages")[2]; s_adv <- vals("Share of loans (credit mix)")[2]
  fell <- which(pbtg < 0)

  tagList(
    # Block 1: the matrix
    div(class = "fade-item",
      h2(class = "section-heading", "Segment Comparison Matrix"),
      p(class = "lead",
        "One table puts every segment side by side on profitability, growth, contribution, funding and credit risk. A headline profit number is an average, and this view shows which segments are strong, which are large, and which are costly to fund."),
      div(class = "slide-card",
        h3(class = "slide-title", "Segment scorecard, Q1 FY27 (standalone)"),
        sm_table_ui(),
        div(class = "mx-legend",
          span("Worse on the row"), span(class = "mx-bar"), span("Better on the row"),
          span(class = "mx-legend-note",
               "Colour runs across each row. #1 is the best segment on that metric. Rows marked \u2013 are descriptive and left uncoloured.")),
        p(class = "drv-note",
          "Corporate/Wholesale loans and slippages combine Corporate with SME (WBCG with CBG). Loan and slippage data are not split for Digital, Other Retail or Treasury. Revenue is gross, before inter-segment elimination, so margins are not comparable with the bank's reported margin. Other Banking Business is left out because its ~93% margin would distort the colours.")
      )
    ),

    # Block 2: headline cards + reading
    div(class = "fade-item",
      h3(class = "sub-heading", "What stands out"),
      p(class = "sub-note", "Strength, size and risk sit in different places."),
      div(class = "stat-grid",
        stat_card(pct(margin[best(margin)]), "Highest PBT margin", nm(best(margin))),
        stat_card(pct(roa[best(roa)], 2), "Highest return on assets", nm(best(roa))),
        stat_card(paste0("+", pct(pbtg[best(pbtg)])), "Fastest PBT growth",
                  paste0(nm(best(pbtg)), ", year on year")),
        stat_card(pct(slr[which.max(slr)], 2), "Highest slippage rate", nm(which.max(slr)), warn = TRUE),
        if (length(fell) > 0)
          stat_card(paste0(sm_minus, pct(abs(pbtg[fell[1]]))), "PBT fell year on year",
                    paste0(nm(fell[1]), " is the only one of the five"), warn = TRUE)
      ),
      div(class = "callout",
        h4("Reading the matrix"),
        p(sprintf("Corporate/Wholesale keeps the most of each rupee of revenue (%s margin) but is the heaviest user of the bank's funds, with liabilities at only %.2fx its assets. Retail is the volume and funding franchise: it brings in %s of gross revenue and holds %s of liabilities. It also carries %s of gross slippages from %s of the loan book, so credit quality is the main risk to its margin. Digital Banking, a part of Retail, earns the best return on assets and shows the fastest profit growth of the five. Treasury's profit fell because its earnings depend on market conditions, not customers.",
                  pct(margin[1]), la[1], pct(s_rev), pct(s_lia), pct(s_slp), pct(s_adv)))
      )
    ),

    # Block 3: margin trend (sheet 1)
    div(class = "fade-item",
      h3(class = "sub-heading", "PBT margin over three quarters"),
      p(class = "sub-note",
        "Margin is segment profit before tax divided by gross segment revenue. Retail's margin has improved sharply, while Treasury's is volatile."),
      div(class = "slide-card",
        h3(class = "slide-title", "PBT margin by segment: Q1 FY26, Q4 FY26 and Q1 FY27"),
        div(class = "replay-chart", echarts4rOutput("sm_margin_plot", height = "50vh"))
      )
    )
  )
}

sm_css <- "
.mx-wrap { overflow-x: auto; }
.mx-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 3px;
  font-size: 0.88rem;
  min-width: 1180px;
}
.mx-table th {
  background: var(--axis-burgundy);
  color: #FFFFFF;
  font-weight: 700;
  text-align: center;
  padding: 10px 8px;
  border-radius: 6px;
}
.mx-table th.mx-metric, .mx-table td.mx-metric { text-align: left; }
.mx-table td.mx-metric { font-weight: 500; padding: 9px 10px; }
.mx-table td { text-align: center; padding: 8px 6px; border-radius: 6px; background: #FFFFFF; }
.mx-table td.mx-dir { font-size: 0.76rem; opacity: 0.7; white-space: nowrap; }
.mx-table td.mx-na { color: #8C8C8C; font-style: italic; background: #F6F2F4; }
.mx-table tr.mx-group td {
  text-align: left;
  background: transparent;
  color: var(--axis-maroon);
  font-weight: 700;
  font-size: 0.8rem;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  padding: 14px 4px 2px 4px;
}
.mx-sub { font-weight: 400; font-size: 0.7rem; opacity: 0.85; }
.mx-val { font-weight: 700; }
.mx-rank { font-size: 0.7rem; opacity: 0.8; margin-top: 1px; }
.mx-legend {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  margin-top: 14px;
  font-size: 0.78rem;
}
.mx-bar {
  display: inline-block;
  width: 140px;
  height: 12px;
  border-radius: 6px;
  background: linear-gradient(to right, #F3E7EC, #97144D);
}
.mx-legend-note { opacity: 0.75; margin-left: 8px; }

/* ---- Table animation ----
   sm_js (below) adds .mx-ready on load (cells start hidden) and toggles .mx-play
   while the table is on screen, so the heat map fills in row by row each time it
   scrolls into view. Without JS the table simply shows. Each cell's start delay
   comes from its --d variable (set in sm_cell). */
.mx-wrap.mx-ready .mx-table td.mx-cell { opacity: 0; }
.mx-wrap.mx-play .mx-table td.mx-cell {
  animation: mxIn 0.6s cubic-bezier(0.22, 1, 0.36, 1) both;
  animation-delay: var(--d, 0s);
}
@keyframes mxIn {
  from { opacity: 0; transform: scale(0.8); background-color: #FFFFFF; }
  to   { opacity: 1; transform: scale(1); }
}
@media (prefers-reduced-motion: reduce) {
  .mx-wrap.mx-ready .mx-table td.mx-cell { opacity: 1; }
  .mx-wrap.mx-play .mx-table td.mx-cell { animation: none; }
}
"

# ---- Replays the table animation each time it scrolls into view (same idea as replay_js).
sm_js <- "
document.addEventListener('DOMContentLoaded', function () {
  var wraps = document.querySelectorAll('.mx-wrap');
  if (!wraps.length || !('IntersectionObserver' in window)) return;   // no support: table stays visible
  var steps = []; for (var i = 0; i <= 20; i++) steps.push(i / 20);
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      var tall = e.rootBounds && e.intersectionRect.height >= e.rootBounds.height * 0.4;
      if (e.isIntersecting && (e.intersectionRatio >= 0.2 || tall)) e.target.classList.add('mx-play');
      else if (e.intersectionRatio === 0) e.target.classList.remove('mx-play');   // reset once fully off screen
    });
  }, { threshold: steps });
  wraps.forEach(function (w) { w.classList.add('mx-ready'); io.observe(w); });
});
"

# ---- Server hook: call segment_matrix_server(output) inside server() ----
segment_matrix_server <- function(output) {
  output$sm_margin_plot <- renderEcharts4r(plot_sm_margin_echarts())
}
