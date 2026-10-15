# ==========================================================
# EDA module: themed ggplot charts + carousel UI + server hook
# Sourced by app.R (needs `data_dir` to be defined first).
# ASCII only: non-ASCII symbols are written as \u escapes.
# ==========================================================

library(ggplot2)
library(scales)

# ---- Optional: Roboto Mono inside the charts ----
# Needs: install.packages(c("showtext", "sysfonts")) and an internet connection.
# If anything fails, charts quietly fall back to the system monospace font.
plot_font <- "mono"
if (requireNamespace("showtext", quietly = TRUE) &&
    requireNamespace("sysfonts", quietly = TRUE)) {
  font_ok <- tryCatch({
    sysfonts::font_add_google("Roboto Mono", "roboto_mono")
    TRUE
  }, error = function(e) FALSE)
  if (font_ok) {
    showtext::showtext_auto()
    showtext::showtext_opts(dpi = 96)
    plot_font <- "roboto_mono"
  }
}

# ---- Palette and theme (Axis Bank look) ----
pal <- list(
  primary = "#97144D",  # burgundy: current period / main series
  maroon  = "#6B0E37",
  rose    = "#D98BA9",  # light rose: prior period / secondary series
  muted   = "#9A8F95",  # grey for negative values
  text    = "#2B2B2B",
  grid    = "#EADDE3"
)

theme_axis <- function(base_size = 18) {
  theme_minimal(base_size = base_size, base_family = plot_font) +
    theme(
      plot.background    = element_rect(fill = "white", colour = NA),
      panel.background   = element_rect(fill = "white", colour = NA),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      panel.grid.major.y = element_line(colour = pal$grid, linewidth = 0.4),
      axis.text          = element_text(colour = pal$text),
      axis.title         = element_text(colour = pal$maroon, face = "bold"),
      legend.position    = "top",
      legend.justification = "left",
      legend.title       = element_blank(),
      legend.text        = element_text(colour = pal$text),
      plot.margin        = margin(10, 24, 10, 10)
    )
}

# ---- Data ----
read_axis <- function(name) {
  read.csv(file.path(data_dir, paste0(name, ".csv")),
           fileEncoding = "UTF-8-BOM", check.names = FALSE, stringsAsFactors = FALSE)
}

profit <- read_axis("01_segment_profitability")
loans  <- read_axis("02_loans_and_deposits")
income <- read_axis("03_income_statement_standalone")
kpis   <- read_axis("05_kpis_by_customer_segment")
recon  <- read_axis("01b_segment_totals_reconciliation")

# Top-level standalone segments for Q1 FY27, biggest PBT first
q1 <- profit[profit$entity == "Standalone" & profit$period == "Q1FY27" &
             !profit$is_subsegment & profit$segment != "Unallocated", ]
q1 <- q1[order(-q1$segment_pbt_cr), ]

# ---- Chart builders ----
txt_size <- 4.8
inr <- "\u20B9"

# One bar per category
simple_bars <- function(d, label_fun, ylab) {
  ggplot(d, aes(x, value)) +
    geom_col(fill = pal$primary, width = 0.6) +
    geom_hline(yintercept = 0, colour = pal$text, linewidth = 0.4) +
    geom_text(aes(label = label_fun(value), vjust = ifelse(value >= 0, -0.4, 1.3)),
              family = plot_font, size = txt_size, colour = pal$text) +
    scale_x_discrete(labels = label_wrap(16)) +
    scale_y_continuous(expand = expansion(mult = c(if (any(d$value < 0)) 0.15 else 0, 0.15))) +
    labs(x = NULL, y = ylab) +
    theme_axis()
}

# Two series side by side (prior = rose, current = burgundy)
grouped_bars <- function(d, fills, label_fun, ylab) {
  ggplot(d, aes(x, value, fill = group)) +
    geom_col(position = position_dodge(width = 0.72), width = 0.66) +
    geom_hline(yintercept = 0, colour = pal$text, linewidth = 0.4) +
    geom_text(aes(label = label_fun(value), vjust = ifelse(value >= 0, -0.4, 1.3)),
              position = position_dodge(width = 0.72),
              family = plot_font, size = txt_size, colour = pal$text) +
    scale_fill_manual(values = fills) +
    scale_x_discrete(labels = label_wrap(18)) +
    scale_y_continuous(expand = expansion(mult = c(if (any(d$value < 0)) 0.15 else 0, 0.15))) +
    labs(x = NULL, y = ylab) +
    theme_axis()
}

plot_pbt <- function() {
  d <- q1
  d$segment <- factor(d$segment, levels = d$segment)
  ggplot(d, aes(segment, segment_pbt_cr)) +
    geom_col(fill = pal$primary, width = 0.6) +
    geom_text(aes(label = paste0(inr, comma(segment_pbt_cr, accuracy = 1), " cr\n",
                                 sprintf("%.1f%%", pbt_margin_pct), " margin")),
              vjust = -0.3, lineheight = 0.95,
              family = plot_font, size = txt_size, colour = pal$text) +
    scale_x_discrete(labels = label_wrap(16)) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.25)), labels = comma) +
    labs(x = NULL, y = paste0("Profit before tax (", inr, " crore)")) +
    theme_axis()
}

plot_growth <- function() {
  n <- nrow(q1)
  d <- data.frame(
    x     = factor(rep(q1$segment, 2), levels = q1$segment),
    group = factor(rep(c("Revenue growth", "PBT growth"), each = n),
                   levels = c("Revenue growth", "PBT growth")),
    value = c(q1$segment_revenue_yoy_pct, q1$segment_pbt_yoy_pct)
  )
  grouped_bars(d, c("Revenue growth" = pal$rose, "PBT growth" = pal$primary),
               function(v) sprintf("%.1f%%", v), "Year-on-year growth (%)")
}

plot_loans <- function() {
  d <- loans[loans$category == "Loans" & loans$customer_segment != "Total", ]
  d <- d[order(-d$yoy_growth_pct), ]
  d <- data.frame(x = factor(d$customer_segment, levels = d$customer_segment),
                  value = d$yoy_growth_pct)
  simple_bars(d, function(v) sprintf("%.1f%%", v), "Loan growth, year on year (%)")
}

plot_deposits <- function() {
  d0 <- loans[loans$category == "Deposits" &
              loans$line_item %in% c("CASA deposits (month-end)", "Term deposits (month-end)"), ]
  d0 <- d0[order(!grepl("^CASA", d0$line_item)), ]
  lab <- ifelse(grepl("^CASA", d0$line_item), "CASA deposits", "Term deposits")
  d <- data.frame(
    x     = factor(rep(lab, 2), levels = lab),
    group = factor(rep(c("June 2025", "June 2026"), each = nrow(d0)),
                   levels = c("June 2025", "June 2026")),
    value = c(d0$jun_2025_cr, d0$jun_2026_cr) / 1e5
  )
  grouped_bars(d, c("June 2025" = pal$rose, "June 2026" = pal$primary),
               function(v) sprintf("%s%.2f lakh cr", inr, v),
               paste0("Deposits (", inr, " lakh crore)"))
}

plot_funding <- function() {
  d <- q1[order(q1$net_funding_position_cr), ]
  d$segment <- factor(d$segment, levels = d$segment)
  d$value <- d$net_funding_position_cr / 1e5
  d$sign  <- ifelse(d$value >= 0, "Net funder", "Net user of funds")
  ggplot(d, aes(value, segment, fill = sign)) +
    geom_col(width = 0.6) +
    geom_vline(xintercept = 0, colour = pal$text, linewidth = 0.5) +
    geom_text(aes(label = sprintf("%+.2f lakh cr", value),
                  hjust = ifelse(value >= 0, -0.1, 1.1)),
              family = plot_font, size = txt_size, colour = pal$text) +
    scale_fill_manual(values = c("Net funder" = pal$primary, "Net user of funds" = pal$muted)) +
    scale_x_continuous(expand = expansion(mult = 0.25)) +
    scale_y_discrete(labels = label_wrap(18)) +
    labs(x = paste0("Net funding position (", inr, " lakh crore)"), y = NULL) +
    theme_axis() +
    theme(panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(colour = pal$grid, linewidth = 0.4))
}

plot_income_growth <- function() {
  m <- c("Interest earned (total)" = "Interest earned",
         "Interest expended" = "Interest expended",
         "Net interest income (derived: 1 - 4)" = "Net interest income",
         "Profit before tax" = "Profit before tax",
         "Net profit" = "Net profit")
  d <- income[income$line_item %in% names(m), ]
  d <- d[match(names(m), d$line_item), ]
  d <- data.frame(x = factor(unname(m), levels = unname(m)),
                  value = (d$Q1FY27 - d$Q1FY26) / d$Q1FY26 * 100)
  simple_bars(d, function(v) sprintf("%.1f%%", v), "Year-on-year growth, Q1 FY27 (%)")
}

plot_ratios <- function() {
  m <- c("Cost-to-income ratio % (derived: opex / operating revenue)" = "Cost-to-income ratio",
         "Provisions as % of operating profit (derived)" = "Provisions as % of operating profit")
  d0 <- income[income$line_item %in% names(m), ]
  d0 <- d0[match(names(m), d0$line_item), ]
  lab <- unname(m)
  d <- data.frame(
    x     = factor(rep(lab, 2), levels = lab),
    group = factor(rep(c("Q1 FY26", "Q1 FY27"), each = nrow(d0)),
                   levels = c("Q1 FY26", "Q1 FY27")),
    value = c(d0$Q1FY26, d0$Q1FY27)
  )
  grouped_bars(d, c("Q1 FY26" = pal$rose, "Q1 FY27" = pal$primary),
               function(v) sprintf("%.1f%%", v), "Percentage (%)")
}

plot_npa <- function() {
  periods <- c("Q1FY26", "Q4FY26", "Q1FY27")
  k <- kpis[kpis$metric %in% c("Gross NPA ratio", "Net NPA ratio") &
            kpis$period %in% periods & kpis$customer_segment == "Bank", ]
  k <- k[!duplicated(k[c("period", "metric")]), ]
  d <- data.frame(
    x     = factor(sub("^Q(\\d)FY(\\d+)$", "Q\\1 FY\\2", k$period),
                   levels = sub("^Q(\\d)FY(\\d+)$", "Q\\1 FY\\2", periods)),
    group = factor(sub(" ratio", "", k$metric), levels = c("Gross NPA", "Net NPA")),
    value = k$value
  )
  grouped_bars(d, c("Gross NPA" = pal$primary, "Net NPA" = pal$rose),
               function(v) sprintf("%.2f%%", v), "NPA ratio (%)")
}

plot_recon <- function() {
  r <- recon[recon$entity == "Standalone" & recon$period %in% c("Q1FY26", "Q1FY27"), ]
  r <- r[match(c("Q1FY26", "Q1FY27"), r$period), ]
  lab <- c("Q1 FY26", "Q1 FY27")
  d <- data.frame(
    x     = factor(rep(lab, 2), levels = lab),
    group = factor(rep(c("Total segment revenue", "Income from operations"), each = nrow(r)),
                   levels = c("Total segment revenue", "Income from operations")),
    value = c(r$total_segment_revenue_cr, r$income_from_operations_cr)
  )
  grouped_bars(d, c("Total segment revenue" = pal$rose, "Income from operations" = pal$primary),
               function(v) paste0(inr, comma(v, accuracy = 1), " cr"),
               paste0("Revenue (", inr, " crore)"))
}


# ---------------------------------------------------------
# Animated versions (echarts4r). The drawing helpers are in modules/echarts_helpers.R.
# The ggplot functions above are kept for reference but are no longer shown.
# ---------------------------------------------------------
pct1 <- function(v) sprintf("%.1f%%", v)

plot_pbt_ec <- function() {
  ec_bar_chart(q1$segment,
    list(list(name = "Profit before tax", color = pal$primary, values = q1$segment_pbt_cr,
              labels = paste0(inr, comma(q1$segment_pbt_cr, accuracy = 1), " cr\n",
                              sprintf("%.1f%%", q1$pbt_margin_pct), " margin"))),
    paste0("Profit before tax (", inr, " crore)"))
}

plot_growth_ec <- function() {
  n <- nrow(q1)
  d <- data.frame(
    x     = factor(rep(q1$segment, 2), levels = q1$segment),
    group = factor(rep(c("Revenue growth", "PBT growth"), each = n),
                   levels = c("Revenue growth", "PBT growth")),
    value = c(q1$segment_revenue_yoy_pct, q1$segment_pbt_yoy_pct))
  ec_bar_chart(q1$segment,
    ec_from_long(d, c("Revenue growth" = pal$rose, "PBT growth" = pal$primary), pct1),
    "Year-on-year growth (%)", wrap = 18)
}

plot_loans_ec <- function() {
  d <- loans[loans$category == "Loans" & loans$customer_segment != "Total", ]
  d <- d[order(-d$yoy_growth_pct), ]
  ec_bar_chart(d$customer_segment,
    list(list(name = "Loan growth", color = pal$primary, values = d$yoy_growth_pct,
              labels = pct1(d$yoy_growth_pct))),
    "Loan growth, year on year (%)")
}

plot_deposits_ec <- function() {
  d0 <- loans[loans$category == "Deposits" &
              loans$line_item %in% c("CASA deposits (month-end)", "Term deposits (month-end)"), ]
  d0 <- d0[order(!grepl("^CASA", d0$line_item)), ]
  lab <- ifelse(grepl("^CASA", d0$line_item), "CASA deposits", "Term deposits")
  lakh <- function(v) sprintf("%s%.2f lakh cr", inr, v)
  ec_bar_chart(lab,
    list(list(name = "June 2025", color = pal$rose,    values = d0$jun_2025_cr / 1e5, labels = lakh(d0$jun_2025_cr / 1e5)),
         list(name = "June 2026", color = pal$primary, values = d0$jun_2026_cr / 1e5, labels = lakh(d0$jun_2026_cr / 1e5))),
    paste0("Deposits (", inr, " lakh crore)"), wrap = 18)
}

plot_funding_ec <- function() {
  d <- q1[order(q1$net_funding_position_cr), ]
  v <- d$net_funding_position_cr / 1e5
  lab <- sprintf("%+.2f lakh cr", v)
  ec_bar_chart(d$segment,
    list(list(name = "Net funder",        color = pal$primary, values = ifelse(v >= 0, v, NA),
              labels = ifelse(v >= 0, lab, NA)),
         list(name = "Net user of funds", color = pal$muted,   values = ifelse(v <  0, v, NA),
              labels = ifelse(v <  0, lab, NA))),
    paste0("Net funding position (", inr, " lakh crore)"),
    horizontal = TRUE, stack = TRUE, wrap = 18)
}

plot_income_growth_ec <- function() {
  m <- c("Interest earned (total)" = "Interest earned",
         "Interest expended" = "Interest expended",
         "Net interest income (derived: 1 - 4)" = "Net interest income",
         "Profit before tax" = "Profit before tax",
         "Net profit" = "Net profit")
  d <- income[income$line_item %in% names(m), ]
  d <- d[match(names(m), d$line_item), ]
  v <- (d$Q1FY27 - d$Q1FY26) / d$Q1FY26 * 100
  ec_bar_chart(unname(m),
    list(list(name = "Growth", color = pal$primary, values = v, labels = pct1(v))),
    "Year-on-year growth, Q1 FY27 (%)")
}

plot_ratios_ec <- function() {
  m <- c("Cost-to-income ratio % (derived: opex / operating revenue)" = "Cost-to-income ratio",
         "Provisions as % of operating profit (derived)" = "Provisions as % of operating profit")
  d0 <- income[income$line_item %in% names(m), ]
  d0 <- d0[match(names(m), d0$line_item), ]
  ec_bar_chart(unname(m),
    list(list(name = "Q1 FY26", color = pal$rose,    values = d0$Q1FY26, labels = pct1(d0$Q1FY26)),
         list(name = "Q1 FY27", color = pal$primary, values = d0$Q1FY27, labels = pct1(d0$Q1FY27))),
    "Percentage (%)", wrap = 18)
}

plot_npa_ec <- function() {
  periods <- c("Q1FY26", "Q4FY26", "Q1FY27")
  k <- kpis[kpis$metric %in% c("Gross NPA ratio", "Net NPA ratio") &
            kpis$period %in% periods & kpis$customer_segment == "Bank", ]
  k <- k[!duplicated(k[c("period", "metric")]), ]
  vals <- function(metric) {
    kk <- k[k$metric == metric, ]
    kk$value[match(periods, kk$period)]
  }
  pct2 <- function(v) sprintf("%.2f%%", v)
  ec_bar_chart(sub("^Q(\\d)FY(\\d+)$", "Q\\1 FY\\2", periods),
    list(list(name = "Gross NPA", color = pal$primary, values = vals("Gross NPA ratio"), labels = pct2(vals("Gross NPA ratio"))),
         list(name = "Net NPA",   color = pal$rose,    values = vals("Net NPA ratio"),   labels = pct2(vals("Net NPA ratio")))),
    "NPA ratio (%)")
}

plot_recon_ec <- function() {
  r <- recon[recon$entity == "Standalone" & recon$period %in% c("Q1FY26", "Q1FY27"), ]
  r <- r[match(c("Q1FY26", "Q1FY27"), r$period), ]
  cr <- function(v) paste0(inr, comma(v, accuracy = 1), " cr")
  ec_bar_chart(c("Q1 FY26", "Q1 FY27"),
    list(list(name = "Total segment revenue",    color = pal$rose,    values = r$total_segment_revenue_cr, labels = cr(r$total_segment_revenue_cr)),
         list(name = "Income from operations",   color = pal$primary, values = r$income_from_operations_cr, labels = cr(r$income_from_operations_cr))),
    paste0("Revenue (", inr, " crore)"))
}

# ---- Carousel content: one entry per slide, in presentation order ----
eda_charts <- list(
  list(title = "Profit before tax by banking segment",
       takeaway = paste0("Retail earns the most PBT (", inr, "3,566 cr) but on ", inr, "38,269 cr of revenue. Corporate earns almost as much (", inr, "3,358 cr) on just ", inr, "14,168 cr, a 23.7% margin against 9.3% for Retail."),
       plot = plot_pbt_ec),
  list(title = "Revenue growth vs profit growth (year on year)",
       takeaway = "Retail PBT grew 148% on revenue growth of 7.4%. Treasury PBT fell 31% on flat revenue (+0.8%), in line with the drop in trading income.",
       plot = plot_growth_ec),
  list(title = "Year-on-year loan growth by customer segment",
       takeaway = "Corporate advances grew 37.5% and SME 25.4%, against 8.4% for Retail. Retail is still the largest book, but its share of advances slipped from 58.8% to 53.6%.",
       plot = plot_loans_ec),
  list(title = "CASA vs term deposits",
       takeaway = "CASA grew 11.4% while term deposits grew 22.8%, so funding is shifting towards the costlier kind of deposit.",
       plot = plot_deposits_ec),
  list(title = "Net funding position by segment",
       takeaway = "Retail is the bank's net funder (about \u20B94.45 lakh crore surplus). Corporate (about \u20B93.61 lakh crore) and Treasury (about \u20B92.94 lakh crore) are net users of those funds.",
       plot = plot_funding_ec),
  list(title = "Year-on-year growth in income and profit",
       takeaway = paste0("Interest expended grew faster (10.5%) than interest earned (9.4%), so NII rose 8.0%. Net profit still grew 22.5%, helped by provisions falling from ", inr, "3,948 cr to ", inr, "2,223 cr."),
       plot = plot_income_growth_ec),
  list(title = "Operating cost and provision ratios",
       takeaway = "Cost-to-income edged up to 45.5% from 44.7%, but provisions fell from 34.3% of operating profit to 19.1%.",
       plot = plot_ratios_ec),
  list(title = "Gross and net NPA ratios",
       takeaway = "Gross NPA improved to 1.28% from 1.57% a year ago, though it is slightly above last quarter's 1.23%. Net NPA tells the same story: 0.45%, 0.37%, 0.39%.",
       plot = plot_npa_ec),
  list(title = "Segment revenue vs income from operations",
       takeaway = "About a third of summed segment revenue is inter-segment transfers (32.7% in Q1 FY26, 34.1% in Q1 FY27), so segment revenue overstates what the bank earns from outside.",
       plot = plot_recon_ec)
)

# ---- Carousel UI ----
eda_carousel_ui <- function(charts = eda_charts) {
  n <- length(charts)
  div(class = "carousel", id = "eda-carousel",
    div(class = "carousel-viewport",
      div(class = "carousel-track", id = "eda-track",
        lapply(seq_len(n), function(i) {
          div(class = "carousel-slide",
            div(class = "slide-card",
              h3(class = "slide-title", charts[[i]]$title),
              div(class = "replay-chart", echarts4rOutput(paste0("eda_plot_", i), height = "46vh")),
              p(class = "slide-takeaway", span(class = "tag", "Takeaway"), charts[[i]]$takeaway)
            )
          )
        })
      )
    ),
    div(class = "carousel-controls",
      tags$button(class = "carousel-btn", id = "eda-prev", `aria-label` = "Previous chart", HTML("&#10094;")),
      div(class = "carousel-dots",
        lapply(seq_len(n), function(i) {
          tags$button(class = "dot", `data-index` = i - 1,
                      `aria-label` = paste("Chart", i, ":", charts[[i]]$title))
        })
      ),
      span(class = "carousel-counter", id = "eda-counter", paste("1 /", n)),
      tags$button(class = "carousel-btn", id = "eda-next", `aria-label` = "Next chart", HTML("&#10095;"))
    )
  )
}

# ---- Carousel server hook: call eda_server(output) inside server() ----
eda_server <- function(output, charts = eda_charts) {
  lapply(seq_along(charts), function(i) {
    output[[paste0("eda_plot_", i)]] <- renderEcharts4r(charts[[i]]$plot())
  })
}
