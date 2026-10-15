# ==========================================================
# Drivers + KPIs module: three driver charts and eight KPI cards
# Sourced by app.R AFTER modules/eda.R (reuses read_axis, pal,
# theme_axis, plot_font, inr). stat_card() comes from app.R and is
# only called when the UI is built. ASCII only: symbols are \u escapes.
# Data: devashish-Driver Breakdown.csv (sections 1-4) and Ratios.csv
# ==========================================================

dk_minus <- "\u2212"

dk_signed <- function(x, prefix = "", suffix = "") {
  paste0(ifelse(x >= 0, "+", dk_minus), prefix, comma(abs(x), accuracy = 1), suffix)
}

# ---- Data ----
drv <- read_axis("devashish-Driver Breakdown")
drv$driver <- trimws(drv$driver)

# Section 1 is only used for the NII start and end values
d_bank <- drv[drv$level == "Bank" & drv$section == "1. PBT bridge", ]
d_pbt_chg <- d_bank$impact_on_pbt_cr[grepl("^End", d_bank$driver)] -
             d_bank$impact_on_pbt_cr[grepl("^Start", d_bank$driver)]

d_nii   <- drv[drv$section == "2. NII volume vs rate", ]
d_nim   <- drv[grepl("^3\\. NIM bridge", drv$section), ]
d_seg   <- drv[drv$level == "Segment", ]

# ---------------------------------------------------------
# 1. NII volume vs rate waterfall
# ---------------------------------------------------------
nii_row   <- d_bank[d_bank$driver == "Net interest income", ]
nii_start <- nii_row$Q1FY26
nii_end   <- nii_row$Q1FY27

nii_labels <- c("Loan growth\n(volume)", "Lower loan\nyields (rate)",
                "More deposits\n(volume)", "Cheaper funds\n(rate)",
                "Other interest\nincome")
nii_steps  <- d_nii$impact_on_pbt_cr
stopifnot(length(nii_steps) == length(nii_labels))

plot_nii <- function() {
  vals   <- c(nii_start, nii_steps, nii_end)
  total  <- c(TRUE, rep(FALSE, length(nii_steps)), TRUE)
  n      <- length(vals)
  from <- numeric(n); to <- numeric(n); run <- 0
  for (i in seq_len(n)) {
    if (total[i]) { from[i] <- 0;   to[i] <- vals[i]; run <- vals[i] }
    else          { from[i] <- run; run <- run + vals[i]; to[i] <- run }
  }
  wf <- data.frame(
    i = seq_len(n), from = from, to = to,
    cat = factor(ifelse(total, "Total", ifelse(vals >= 0, "Increase", "Decrease")),
                 levels = c("Total", "Increase", "Decrease")),
    lab = ifelse(total, comma(vals, accuracy = 1), dk_signed(vals))
  )
  wf$top <- pmax(wf$from, wf$to)
  wf$bot <- pmin(wf$from, wf$to)
  conn <- data.frame(x = seq_len(n - 1) + 0.34, xend = seq_len(n - 1) + 1 - 0.34, y = to[-n])
  lo <- floor(min(wf$bot[!total]) * 0.85 / 1000) * 1000
  hi <- ceiling(max(wf$top) * 1.06 / 500) * 500

  ggplot() +
    geom_segment(data = conn, aes(x = x, xend = xend, y = y, yend = y),
                 linetype = "dotted", colour = pal$muted, linewidth = 0.5) +
    geom_rect(data = wf, aes(xmin = i - 0.34, xmax = i + 0.34, ymin = bot, ymax = top, fill = cat)) +
    geom_text(data = wf, aes(x = i, y = top, label = lab), vjust = -0.6,
              family = plot_font, size = 5.2, fontface = "bold", colour = pal$text) +
    scale_fill_manual(values = c("Total" = "#3D3D3D", "Increase" = pal$primary,
                                 "Decrease" = pal$muted)) +
    scale_x_continuous(breaks = seq_len(n),
                       labels = c("NII\nQ1 FY26", nii_labels, "NII\nQ1 FY27"),
                       expand = expansion(add = 0.5)) +
    scale_y_continuous(labels = comma) +
    coord_cartesian(ylim = c(lo, hi)) +
    labs(x = NULL, y = paste0("Net interest income (", inr, " crore)")) +
    theme_axis()
}

# ---------------------------------------------------------
# 2. NIM bridge (management, basis points)
# ---------------------------------------------------------
nim_i_yoy <- which(grepl("^NIM YoY change", d_nim$driver))
nim_i_qoq <- which(grepl("^NIM QoQ change", d_nim$driver))
nim_yoy   <- d_nim[(nim_i_yoy + 1):(nim_i_qoq - 1), ]
nim_qoq   <- d_nim[(nim_i_qoq + 1):nrow(d_nim), ]
nim_tot_yoy <- d_nim$Q1FY27[nim_i_yoy]
nim_tot_qoq <- d_nim$Q1FY27[nim_i_qoq]

nim_yoy_labels <- c("Repo rate cuts, net\nof deposit repricing", "Balance sheet\nmix")
nim_qoq_labels <- c("Agri slippage\ninterest reversal", "Balance sheet\nmix", "Loan\npricing")
stopifnot(nrow(nim_yoy) == length(nim_yoy_labels), nrow(nim_qoq) == length(nim_qoq_labels))

plot_nim <- function() {
  p1 <- sprintf("Versus a year ago (total %s%d bps)", dk_minus, abs(nim_tot_yoy))
  p2 <- sprintf("Versus last quarter (total %s%d bps)", dk_minus, abs(nim_tot_qoq))
  d <- rbind(
    data.frame(panel = p1, comp = nim_yoy_labels, bps = nim_yoy$Q1FY27, stringsAsFactors = FALSE),
    data.frame(panel = p2, comp = nim_qoq_labels, bps = nim_qoq$Q1FY27, stringsAsFactors = FALSE)
  )
  d$panel <- factor(d$panel, levels = c(p1, p2))
  d$comp  <- factor(d$comp, levels = unique(d$comp))
  d$lab   <- paste0(ifelse(d$bps >= 0, "+", dk_minus), abs(d$bps), " bps")

  ggplot(d, aes(x = comp, y = bps)) +
    geom_hline(yintercept = 0, colour = pal$muted, linewidth = 0.4) +
    geom_col(fill = pal$primary, width = 0.55) +
    geom_text(aes(label = lab), vjust = 1.5, family = plot_font, size = 5.2,
              fontface = "bold", colour = pal$text) +
    facet_wrap(~panel, scales = "free_x") +
    scale_x_discrete(position = "top") +
    scale_y_continuous(expand = expansion(mult = c(0.25, 0.05))) +
    labs(x = NULL, y = "Change in net interest margin (basis points)") +
    theme_axis() +
    theme(strip.text = element_text(colour = pal$maroon, face = "bold", hjust = 0, size = 15),
          panel.grid.major.y = element_blank(),
          axis.text.y = element_blank())
}

# ---------------------------------------------------------
# 3. Segment bridge: revenue, implied cost and PBT change
# ---------------------------------------------------------
seg_main  <- c("Retail Banking", "Corporate/Wholesale Banking", "Treasury", "Other Banking Business")
seg_axis  <- c("Retail\nBanking", "Corporate/\nWholesale", "Treasury", "Other\nBanking")
seg_get <- function(seg, kind) {
  r <- d_seg[sub(":.*$", "", d_seg$driver) == seg & grepl(kind, d_seg$driver), ]
  r$impact_on_pbt_cr[1]
}
seg_tab <- data.frame(
  seg  = seg_main,
  rev  = sapply(seg_main, seg_get, kind = "revenue change"),
  cost = sapply(seg_main, seg_get, kind = "implied cost change"),
  pbt  = sapply(seg_main, seg_get, kind = "PBT change"),
  row.names = NULL, stringsAsFactors = FALSE
)

plot_seg <- function() {
  meas <- c("Revenue change", "Cost change (negative = costs rose)", "Profit before tax change")
  d <- data.frame(
    seg  = factor(rep(seg_axis, 3), levels = seg_axis),
    meas = factor(rep(meas, each = nrow(seg_tab)), levels = meas),
    val  = c(seg_tab$rev, seg_tab$cost, seg_tab$pbt)
  )
  d$lab <- dk_signed(d$val)
  dodge <- position_dodge(width = 0.8)
  ggplot(d, aes(x = seg, y = val, fill = meas)) +
    geom_hline(yintercept = 0, colour = pal$muted, linewidth = 0.4) +
    geom_col(position = dodge, width = 0.72) +
    geom_text(aes(label = lab, vjust = ifelse(val >= 0, -0.5, 1.4)),
              position = dodge, family = plot_font, size = 4.4, colour = pal$text) +
    scale_fill_manual(values = setNames(c(pal$rose, pal$muted, pal$primary), meas)) +
    scale_y_continuous(labels = comma, expand = expansion(mult = c(0.12, 0.12))) +
    labs(x = NULL, y = paste0("Change, Q1 FY26 to Q1 FY27 (", inr, " crore)")) +
    theme_axis()
}

# ---------------------------------------------------------
# Animated versions (echarts4r). Drawing helpers live in modules/echarts_helpers.R.
# The ggplot functions above are kept for reference but are no longer shown.
# ---------------------------------------------------------
plot_nii_echarts <- function() {
  ec_waterfall(
    vals      = c(nii_start, nii_steps, nii_end),
    is_total  = c(TRUE, rep(FALSE, length(nii_steps)), TRUE),
    x_labels  = c("NII\nQ1 FY26", nii_labels, "NII\nQ1 FY27"),
    tip_names = gsub("\n", " ", c("Net interest income, Q1 FY26", nii_labels, "Net interest income, Q1 FY27")),
    y_title   = paste0("Net interest income (", inr, " crore)"),
    lo_mult = 0.85, hi_mult = 1.06,
    legend_names = c("Total", "Increase", "Decrease")
  )
}

# NIM bridge: two panels side by side (year on year, quarter on quarter).
# Drawn as one axis with a blank gap between the two groups, so both panels
# share the same zero line and scale.
plot_nim_echarts <- function() {
  p1 <- sprintf("Versus a year ago (total %s%d bps)", dk_minus, abs(nim_tot_yoy))
  p2 <- sprintf("Versus last quarter (total %s%d bps)", dk_minus, abs(nim_tot_qoq))
  n1 <- length(nim_yoy_labels); n2 <- length(nim_qoq_labels)
  cats <- c(nim_yoy_labels, " ", nim_qoq_labels)
  vals <- c(nim_yoy$Q1FY27, NA, nim_qoq$Q1FY27)
  rng  <- range(c(vals, 0), na.rm = TRUE)
  ymin <- if (rng[1] < 0) rng[1] * 1.4 else 0
  ymax <- if (rng[2] > 0) rng[2] * 1.4 else 0

  item <- function(v) if (is.na(v)) "-" else
    list(value = v, label = list(position = if (v >= 0) "top" else "bottom"))

  title_style <- list(color = pal$maroon, fontWeight = "bold", fontSize = 18, fontFamily = ec_mono)
  # echarts only takes px or % for positions, so the second title is placed as a
  # percentage (the plot spans 20px .. width - 20px; worked out for a ~1200px-wide card)
  second_left <- sprintf("%.1f%%", (20 + 1160 * (n1 + 1) / (n1 + n2 + 1)) / 1200 * 100)
  titles <- list(
    list(text = p1, left = 20, top = 0, textStyle = title_style),
    list(text = p2, left = second_left, top = 0, textStyle = title_style))

  opt <- c(ec_motion(), list(
    title = titles,
    grid  = list(left = 20, right = 20, top = 120, bottom = 10),
    tooltip = ec_tooltip("item", sprintf(
      "function (p) { var v = Number(p.value); return '<b>' + String(p.name).replace(/\\n/g, ' ') + '</b><br/>' + (v >= 0 ? '+' : '%s') + Math.abs(v) + ' bps'; }",
      dk_minus)),
    xAxis = list(type = "category", position = "top", data = as.list(cats),
                 axisTick = list(show = FALSE),
                 axisLine = list(lineStyle = list(color = pal$muted)),
                 axisLabel = list(interval = 0, fontSize = 17, lineHeight = 24,
                                  color = pal$text, margin = 14)),
    # no axis title here: a rotated axis name on a hidden axis shrinks the plot area in echarts.
    # The unit is on every label ("bps") and in the note under the chart.
    yAxis = list(type = "value", min = ymin, max = ymax,
                 axisLabel = list(show = FALSE), axisLine = list(show = FALSE),
                 axisTick = list(show = FALSE), splitLine = list(show = FALSE)),
    series = list(list(
      name = "NIM change", type = "bar", barWidth = "55%",
      data = lapply(vals, item),
      itemStyle = list(color = pal$primary, borderRadius = c(0, 0, 6, 6)),
      emphasis = list(disabled = TRUE),
      label = list(show = TRUE, fontSize = 20, fontWeight = "bold", color = pal$text, distance = 8,
                   formatter = ec_js(sprintf("function (p) { var v = Number(p.value); return (v >= 0 ? '+' : '%s') + Math.abs(v) + ' bps'; }", dk_minus)))
    ))
  ))
  e_list(e_charts(), opt)
}

# Segment bridge: revenue, cost and profit change per segment (grouped bars)
plot_seg_echarts <- function() {
  meas <- c("Revenue change", "Cost change (negative = costs rose)", "Profit before tax change")
  cols <- c(pal$rose, pal$muted, pal$primary)
  vals <- list(seg_tab$rev, seg_tab$cost, seg_tab$pbt)
  item <- function(v) list(value = v,
    label = list(position = if (v >= 0) "top" else "bottom"))

  series <- lapply(1:3, function(k) list(
    name = meas[k], type = "bar", barCategoryGap = "28%", barGap = "6%",
    data = lapply(vals[[k]], item),
    itemStyle = list(color = cols[k], borderRadius = c(5, 5, 0, 0)),
    markLine = if (k == 1) list(silent = TRUE, symbol = "none", animation = FALSE,
                                lineStyle = list(color = pal$muted, width = 1.2, type = "solid"),
                                label = list(show = FALSE), data = list(list(yAxis = 0))),
    emphasis = list(disabled = TRUE),
    label = list(show = TRUE, fontSize = 15, color = pal$text, distance = 6,
                 formatter = ec_js(sprintf("function (p) { var v = Number(p.value); return (v >= 0 ? '+' : '%s') + Math.abs(Math.round(v)).toLocaleString('en-US'); }", dk_minus)))
  ))

  opt <- c(ec_motion(), list(
    legend  = ec_legend(meas),
    # extra headroom: the three long legend entries can wrap onto a second line on narrow screens
    grid    = list(left = 70, right = 24, top = 104, bottom = 8, containLabel = TRUE),
    tooltip = ec_tooltip("axis", ec_tip_signed(" cr")),
    xAxis = list(type = "category", data = as.list(seg_axis),
                 axisTick = list(show = FALSE),
                 # onZero = FALSE keeps the category names at the bottom of the plot;
                 # the zero line is drawn separately (markLine on the first series)
                 axisLine = list(onZero = FALSE, lineStyle = list(color = pal$grid)),
                 axisLabel = list(interval = 0, fontSize = 17, lineHeight = 24, color = pal$text)),
    yAxis = c(list(type = "value", boundaryGap = c("12%", "12%"),
                   axisLabel = list(fontSize = 16, color = pal$text,
                                    formatter = ec_js("function (v) { return v.toLocaleString('en-US'); }")),
                   splitLine = list(lineStyle = list(color = pal$grid))),
              ec_value_axis_title(paste0("Change, Q1 FY26 to Q1 FY27 (", inr, " crore)"), gap = 78)),
    series = series
  ))
  e_list(e_charts(), opt)
}

# ---------------------------------------------------------
# Eight KPIs, read from Ratios.csv (edit this table to swap KPIs)
#   good = "up": a rise is favourable, "down": a fall is favourable,
#   "none": no judgement (card is never red)
# ---------------------------------------------------------
ratios <- read_axis("Ratios")

kpi_defs <- data.frame(
  ratio  = c("Net interest margin", "Yield on advances (approx.)", "Cost of funds (approx.)",
             "Return on equity (annualized)",
             "CASA ratio (month-end)", "Credit-deposit ratio", "Gross NPA ratio", "Net credit cost"),
  label  = c("Net interest margin", "Yield on advances", "Cost of funds", "Return on equity",
             "CASA ratio", "Credit-deposit ratio", "Gross NPA ratio", "Net credit cost"),
  digits = c(2, 2, 2, 2, 1, 2, 2, 2),
  good   = c("up", "up", "down", "up", "up", "none", "down", "down"),
  means  = c("What the bank keeps as a spread on its lending",
             "Average interest earned on loans (approx.)",
             "Average interest paid on deposits and borrowings (approx.)",
             "Profit earned per rupee of shareholder equity",
             "Share of deposits held in cheap savings and current accounts (month-end)",
             "Loans given for every rupee of deposits",
             "Share of loans that have gone bad",
             "Yearly charge for bad loans, as a share of loans"),
  stringsAsFactors = FALSE
)

kpi_data <- local({
  r <- ratios[match(kpi_defs$ratio, ratios$ratio), ]
  stopifnot(!anyNA(r$Q1FY27), !anyNA(r$Q1FY26))
  kpi_defs$now  <- r$Q1FY27
  kpi_defs$prev <- r$Q1FY26
  kpi_defs$chg  <- round(r$Q1FY27 - r$Q1FY26, 2)   # recomputed so it matches the displayed values
  kpi_defs
})

kpi_get <- function(name) kpi_data[kpi_data$ratio == name, ]

kpi_card <- function(k) {
  fmt <- function(x) sprintf(paste0("%.", k$digits, "f%%"), x)
  moved_bad <- (k$good == "up" && k$chg < 0) || (k$good == "down" && k$chg > 0)
  change <- sprintf("%s %s points from %s a year ago",
                    ifelse(k$chg >= 0, "Up", "Down"),
                    sprintf(paste0("%.", k$digits, "f"), abs(k$chg)), fmt(k$prev))
  div(class = if (moved_bad) "stat-card warn" else "stat-card",
    div(class = "stat-value", fmt(k$now)),
    div(class = "stat-label", k$label),
    div(class = "stat-note", change),
    div(class = "stat-note", k$means)
  )
}

kpi_cards <- function(rows) lapply(rows, function(i) kpi_card(kpi_data[i, ]))

# ---------------------------------------------------------
# Section content
# ---------------------------------------------------------
drivers_ui <- function() {
  adv_vol <- d_nii$impact_on_pbt_cr[1]; adv_rate <- d_nii$impact_on_pbt_cr[2]
  dep_vol <- d_nii$impact_on_pbt_cr[3]; dep_rate <- d_nii$impact_on_pbt_cr[4]
  oth     <- d_nii$impact_on_pbt_cr[5]
  vol_net  <- adv_vol + dep_vol
  rate_net <- adv_rate + dep_rate
  tot_comp <- sum(nim_yoy$Q1FY27)
  retail   <- seg_tab[seg_tab$seg == "Retail Banking", ]
  treas    <- seg_tab[seg_tab$seg == "Treasury", ]

  seg_note <- function(i) {
    s <- seg_tab[i, ]
    paste0("Revenue ", dk_signed(s$rev, inr, " cr"), "; costs ", dk_signed(s$cost, inr, " cr"))
  }
  sub_get <- function(seg) seg_get(seg, "PBT change")

  tagList(
    # Block 1: NII volume vs rate
    div(class = "fade-item",
      h2(class = "section-heading", "Driver Breakdown"),
      p(class = "lead",
        "The profit bridge showed what moved profit. The drivers show why. Net interest income, the bank's largest income line, is split into the effect of a bigger balance sheet (volume) and the effect of changing interest rates (rate)."),
      div(class = "slide-card",
        h3(class = "slide-title", "Net interest income: volume versus rate, Q1 FY26 to Q1 FY27"),
        div(class = "replay-chart", echarts4rOutput("drv_nii_plot", height = "50vh")),
        p(class = "drv-note",
          "Volume effect is last year's interest multiplied by the growth in loans or funding. Rate effect is what is left over. Both use period-end balances, so they are approximations.")
      )
    ),

    # Block 2: what NII says + NIM bridge
    div(class = "fade-item",
      h3(class = "sub-heading", "Growth in volume, pressure on rate"),
      p(class = "sub-note",
        "Net interest income rose, but margin (the spread earned per rupee of assets) fell."),
      div(class = "stat-grid",
        stat_card(dk_signed(vol_net, inr, " cr"), "Net volume effect",
                  paste0("Loans added ", dk_signed(adv_vol, inr, " cr"), " of interest; extra funding cost ", dk_signed(dep_vol, inr, " cr"))),
        stat_card(dk_signed(rate_net, inr, " cr"), "Net rate effect",
                  paste0("Lower loan yields ", dk_signed(adv_rate, inr, " cr"), "; cheaper funding ", dk_signed(dep_rate, inr, " cr")),
                  warn = rate_net < 0),
        stat_card(dk_signed(oth, inr, " cr"), "Other interest income", "Investments and RBI balances")
      ),
      div(class = "slide-card", style = "margin-top: 24px;",
        h3(class = "slide-title", "Net interest margin: why it narrowed (management's bridge)"),
        div(class = "replay-chart", echarts4rOutput("drv_nim_plot", height = "46vh")),
        p(class = "drv-note",
          sprintf("Figures are from the CFO on the earnings call, in basis points (100 bps = 1 percentage point). The year-on-year parts add to %s%d bps against a reported %s%d bps, a rounding gap of 1 bp.",
                  dk_minus, abs(tot_comp), dk_minus, abs(nim_tot_yoy)))
      )
    ),

    # Block 3: segment bridge
    div(class = "fade-item",
      h3(class = "sub-heading", "Segment bridge"),
      p(class = "sub-note",
        "Revenue change minus the change in all costs gives the change in profit for each segment. Costs combine internal funding charges, operating expenses and provisions, which the bank does not split by segment."),
      div(class = "slide-card",
        h3(class = "slide-title", "Where the profit growth came from, by segment"),
        div(class = "replay-chart", echarts4rOutput("drv_seg_plot", height = "50vh"))
      ),
      div(class = "stat-grid", style = "margin-top: 24px;",
        stat_card(dk_signed(retail$pbt, inr, " cr"), "Retail Banking", seg_note(1)),
        stat_card(dk_signed(seg_tab$pbt[2], inr, " cr"), "Corporate/Wholesale", seg_note(2)),
        stat_card(dk_signed(treas$pbt, inr, " cr"), "Treasury", seg_note(3), warn = treas$pbt < 0),
        stat_card(dk_signed(seg_tab$pbt[4], inr, " cr"), "Other Banking Business", seg_note(4), warn = seg_tab$pbt[4] < 0)
      ),
      div(class = "callout",
        h4("Retail carried the quarter"),
        p(sprintf("Retail Banking added %s cr of profit before tax, which is %.0f%% of the bank's total increase of %s cr (%s cr from Digital Banking and %s cr from other retail). Treasury fell by %s cr as last year's bond gains did not repeat. Segment profits do not add exactly to the bank total because unallocated items sit outside the segments.",
                  paste0(inr, comma(retail$pbt, accuracy = 1)), retail$pbt / d_pbt_chg * 100,
                  paste0(inr, comma(d_pbt_chg, accuracy = 1)),
                  paste0(inr, comma(sub_get("Digital Banking"), accuracy = 1)),
                  paste0(inr, comma(sub_get("Other Retail Banking"), accuracy = 1)),
                  paste0(inr, comma(abs(treas$pbt), accuracy = 1))))
      )
    )
  )
}

kpis_ui <- function() {
  g <- function(n) kpi_get(n)
  nim <- g("Net interest margin"); yld <- g("Yield on advances (approx.)")
  cof <- g("Cost of funds (approx.)"); roe <- g("Return on equity (annualized)")
  casa <- g("CASA ratio (month-end)"); nccost <- g("Net credit cost")

  tagList(
    div(class = "fade-item",
      h2(class = "section-heading", "Eight KPIs"),
      p(class = "lead",
        "Eight numbers that summarise how Axis earns, funds itself and manages risk. Each is compared with a year ago. Red means the change is unfavourable for the bank; the credit-deposit ratio is shown without a judgement."),
      h3(class = "sub-heading", "Earning power"),
      div(class = "stat-grid", kpi_cards(1:4)),
      h3(class = "sub-heading", style = "margin-top: 36px;", "Funding and credit risk"),
      div(class = "stat-grid", kpi_cards(5:8)),
      p(class = "drv-note", style = "margin-top: 16px;",
        "Yield on advances and cost of funds are approximations built from period-end balances, as labelled in the Ratios data. The other six are reported or calculated directly from reported figures.")
    ),
    div(class = "fade-item",
      div(class = "callout",
        h4("Reading the KPIs together"),
        p(sprintf("Loan yields fell %.2f points but the cost of funds fell only %.2f, so the margin narrowed by %.2f points to %.2f%%. The CASA ratio also slipped %.1f points to %.1f%%, so the funding base is less cheap than before. Against that, the net credit cost fell %.2f points to %.2f%%, and return on equity still rose %.2f points to %.2f%%. Profit held up because fewer loans went bad, not because the lending spread improved.",
                  abs(yld$chg), abs(cof$chg), abs(nim$chg), nim$now,
                  abs(casa$chg), casa$now, abs(nccost$chg), nccost$now, roe$chg, roe$now))
      )
    )
  )
}

dk_css <- "
.drv-note {
  margin: 10px 0 0 0;
  font-size: 0.78rem;
  line-height: 1.6;
  opacity: 0.75;
}
"

# ---- Server hook: call drivers_kpis_server(output) inside server() ----
drivers_kpis_server <- function(output) {
  output$drv_nii_plot <- renderEcharts4r(plot_nii_echarts())
  output$drv_nim_plot <- renderEcharts4r(plot_nim_echarts())
  output$drv_seg_plot <- renderEcharts4r(plot_seg_echarts())
}
