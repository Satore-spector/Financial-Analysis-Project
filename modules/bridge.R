# ==========================================================
# Profit bridge module: themed waterfall chart, KPI cards, table
# Sourced by app.R AFTER modules/eda.R (reuses read_axis, pal,
# theme_axis, plot_font, inr). ASCII only: symbols are \u escapes.
# Data: "1. PBT bridge" rows of devashish-Driver Breakdown.csv
# ==========================================================

minus <- "\u2212"

# ---- Data ----
bridge_raw <- read_axis("devashish-Driver Breakdown")
bridge_raw <- bridge_raw[bridge_raw$level == "Bank" & bridge_raw$section == "1. PBT bridge", ]

b_n     <- nrow(bridge_raw)
b_total <- grepl("^(Start|End)", bridge_raw$driver)
b_val   <- bridge_raw$impact_on_pbt_cr

# Running totals so each floating bar starts where the last one ended
b_from <- numeric(b_n); b_to <- numeric(b_n); run <- 0
for (i in seq_len(b_n)) {
  if (b_total[i]) { b_from[i] <- 0;   b_to[i] <- b_val[i]; run <- b_val[i] }
  else            { b_from[i] <- run; run <- run + b_val[i]; b_to[i] <- run }
}

bridge_axis_labels <- c(
  "Start: PBT Q1FY26"    = "PBT\nQ1 FY26",
  "Net interest income"  = "Net interest\nincome",
  "Fee income"           = "Fee\nincome",
  "Trading income"       = "Trading\nincome",
  "Miscellaneous income" = "Misc.\nincome",
  "Operating expenses"   = "Operating\nexpenses",
  "Provisions"           = "Lower\nprovisions",
  "End: PBT Q1FY27"      = "PBT\nQ1 FY27"
)

# ---- Chart ----
plot_bridge <- function() {
  wf <- data.frame(
    i    = seq_len(b_n),
    from = b_from,
    to   = b_to,
    cat  = factor(ifelse(b_total, "Total", ifelse(b_val >= 0, "Adds to profit", "Reduces profit")),
                  levels = c("Total", "Adds to profit", "Reduces profit")),
    lab  = ifelse(b_total, comma(b_val, accuracy = 1),
                  paste0(ifelse(b_val >= 0, "+", minus), comma(abs(b_val), accuracy = 1)))
  )
  wf$top <- pmax(wf$from, wf$to)
  wf$bot <- pmin(wf$from, wf$to)

  conn <- data.frame(x = seq_len(b_n - 1) + 0.34, xend = seq_len(b_n - 1) + 1 - 0.34,
                     y = b_to[-b_n])

  lo <- floor(min(wf$bot[!b_total]) * 0.8 / 1000) * 1000
  hi <- ceiling(max(wf$top) * 1.04 / 500) * 500

  ggplot() +
    geom_segment(data = conn, aes(x = x, xend = xend, y = y, yend = y),
                 linetype = "dotted", colour = pal$muted, linewidth = 0.5) +
    geom_rect(data = wf, aes(xmin = i - 0.34, xmax = i + 0.34, ymin = bot, ymax = top, fill = cat)) +
    geom_text(data = wf, aes(x = i, y = top, label = lab), vjust = -0.6,
              family = plot_font, size = 3.8, fontface = "bold", colour = pal$text) +
    scale_fill_manual(values = c("Total" = "#3D3D3D", "Adds to profit" = pal$primary,
                                 "Reduces profit" = pal$muted)) +
    scale_x_continuous(breaks = seq_len(b_n), labels = unname(bridge_axis_labels[bridge_raw$driver]),
                       expand = expansion(add = 0.5)) +
    scale_y_continuous(labels = comma) +
    coord_cartesian(ylim = c(lo, hi)) +
    labs(x = NULL, y = paste0("Profit before tax (", inr, " crore)")) +
    theme_axis()
}

# ---- Figures used in the cards and notes (all computed from the CSV) ----
bridge_stats <- local({
  pick <- function(name) b_val[bridge_raw$driver == name]
  start <- b_val[1]; end <- b_val[b_n]
  list(start = start, end = end, chg = end - start,
       nii = pick("Net interest income"), fee = pick("Fee income"),
       trading = pick("Trading income"), misc = pick("Miscellaneous income"),
       opex = pick("Operating expenses"), prov = pick("Provisions"),
       gap = end - sum(b_val[-b_n]))
})

fmt_signed <- function(x) paste0(ifelse(x >= 0, "+", minus), inr, comma(abs(x), accuracy = 1), " cr")

# ---- Table ----
bridge_table_labels <- c(
  "Start: PBT Q1FY26"    = "Profit before tax, Q1 FY26",
  "Net interest income"  = "Net interest income",
  "Fee income"           = "Fee income",
  "Trading income"       = "Trading income (bond gains)",
  "Miscellaneous income" = "Miscellaneous income",
  "Operating expenses"   = "Operating expenses (cost up)",
  "Provisions"           = "Provisions (cost down)",
  "End: PBT Q1FY27"      = "Profit before tax, Q1 FY27"
)

bridge_table_ui <- function() {
  cell <- function(x) if (is.na(x)) "" else comma(x, accuracy = 1)
  rows <- lapply(seq_len(b_n), function(i) {
    eff <- if (b_total[i]) comma(b_val[i], accuracy = 1) else
      paste0(ifelse(b_val[i] >= 0, "+", minus), comma(abs(b_val[i]), accuracy = 1))
    tags$tr(class = if (b_total[i]) "total" else NULL,
      tags$td(unname(bridge_table_labels[bridge_raw$driver[i]])),
      tags$td(cell(bridge_raw$Q1FY26[i])),
      tags$td(cell(bridge_raw$Q1FY27[i])),
      tags$td(class = if (b_total[i]) NULL else if (b_val[i] >= 0) "pos" else "neg", eff)
    )
  })
  div(class = "table-wrap",
    tags$table(class = "bridge-table",
      tags$thead(tags$tr(
        tags$th("Step"), tags$th("Q1 FY26"), tags$th("Q1 FY27"),
        tags$th(paste0("Effect on profit (", inr, " cr)")))),
      tags$tbody(rows)
    )
  )
}

# ---- Section content (three fading blocks) ----
bridge_ui <- function() {
  s <- bridge_stats
  tagList(
    # Chart
    div(class = "fade-item",
      h2(class = "section-heading", "Profit Bridge"),
      p(class = "lead",
        "A profit bridge starts with last year's profit, adds or subtracts each change, and ends at this year's profit. It shows exactly where the extra profit came from, and whether it came from the core business or from items that may not repeat."),
      div(class = "slide-card",
        h3(class = "slide-title", "Profit before tax bridge, Q1 FY26 to Q1 FY27 (standalone)"),
        plotOutput("bridge_plot", height = "50vh"),
        p(class = "bridge-note",
          paste0("Dark bars are totals, burgundy bars add to profit, grey bars reduce it. The vertical axis starts above zero so the smaller steps stay visible. ",
                 "The steps add to ", inr, comma(sum(b_val[-b_n]), accuracy = 1),
                 " cr against the reported ", inr, comma(s$end, accuracy = 1),
                 " cr: fee, trading and miscellaneous income come from the press release, which rounds to whole crores (a ",
                 inr, sprintf("%.2f", s$gap), " cr gap)."))
      )
    ),

    # Cards + takeaway
    div(class = "fade-item",
      h3(class = "sub-heading", "What the bridge says"),
      p(class = "sub-note", "Profit before tax rose, but one step did most of the work."),
      div(class = "stat-grid",
        stat_card(fmt_signed(s$chg), "Profit before tax",
                  sprintf("Up %.1f%% from %s%s cr", s$chg / s$start * 100, inr, comma(s$start, accuracy = 1))),
        stat_card(fmt_signed(s$prov), "Lower provisions",
                  sprintf("%.0f%% of the increase", s$prov / s$chg * 100)),
        stat_card(fmt_signed(s$nii), "Net interest income", paste0("Plus ", fmt_signed(s$fee), " from fees")),
        stat_card(fmt_signed(s$trading), "Trading income", "Q1 FY26 had large bond gains", warn = TRUE),
        stat_card(fmt_signed(s$opex), "Operating expenses", "A normal rise for a growing bank", warn = TRUE)
      ),
      div(class = "callout",
        h4("Quality of the growth"),
        p(paste0("Most of the profit growth came from a lower charge for bad loans, not from the core business. Net interest income and fees did add profit, but trading income fell because last year's bond gains did not repeat. ",
                 "The provisions fall reflects better credit quality (net credit cost down from 1.38% to 0.63%), yet a lower provision charge is less certain to repeat than interest or fee growth."))
      )
    ),

    # Table + method
    div(class = "fade-item",
      h3(class = "sub-heading", "How the bridge is built"),
      p(class = "sub-note",
        "For each line of the profit and loss account, take Q1 FY27 minus Q1 FY26. Income lines keep their sign. Cost lines get the opposite sign, because a higher cost lowers profit. The steps are added to last year's profit and must land on this year's profit."),
      bridge_table_ui()
    )
  )
}

bridge_css <- "
.table-wrap { overflow-x: auto; max-width: 1000px; }
.bridge-table {
  width: 100%;
  border-collapse: collapse;
  background: #FFFFFF;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(107, 14, 55, 0.08);
  font-size: 0.9rem;
}
.bridge-table th {
  background: var(--axis-burgundy);
  color: #FFFFFF;
  font-weight: 700;
  text-align: right;
  padding: 12px 16px;
}
.bridge-table td {
  padding: 11px 16px;
  text-align: right;
  border-bottom: 1px solid #EADDE3;
}
.bridge-table th:first-child, .bridge-table td:first-child { text-align: left; }
.bridge-table tr.total td { font-weight: 700; background: var(--axis-light); }
.bridge-table td.pos { color: var(--axis-burgundy); font-weight: 500; }
.bridge-table td.neg { color: #C0392B; font-weight: 500; }
.bridge-note {
  margin: 10px 0 0 0;
  font-size: 0.78rem;
  line-height: 1.6;
  opacity: 0.75;
}
"

# ---- Server hook: call bridge_server(output) inside server() ----
bridge_server <- function(output) {
  output$bridge_plot <- renderPlot(plot_bridge(), res = 96, bg = "white")
}
