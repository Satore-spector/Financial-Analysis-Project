# ==========================================================
# echarts helpers: shared by the animated charts (bridge, drivers).
# Sourced by app.R AFTER modules/eda.R (reuses pal, inr, comma).
# Every chart is a plain echarts option list passed through e_list(),
# so any setting from the echarts documentation can be added to it.
# ASCII only: symbols are \u escapes.
# ==========================================================
library(echarts4r)

ec_mono  <- "Roboto Mono, monospace"
ec_minus <- "\u2212"
ec_js    <- htmlwidgets::JS

ec_signed <- function(x, prefix = "", suffix = "") {
  paste0(ifelse(x >= 0, "+", ec_minus), prefix, comma(abs(x), accuracy = 1), suffix)
}

# A chart that animates in: bars grow one after another
ec_motion <- function() {
  list(animation = TRUE, animationDuration = 1100, animationEasing = "cubicOut",
       animationDelay = ec_js("function (idx) { return idx * 160; }"),
       textStyle = list(fontFamily = ec_mono, color = pal$text))
}

ec_tooltip <- function(trigger = "axis", formatter = NULL) {
  tt <- list(trigger = trigger, axisPointer = list(type = "none"),
             backgroundColor = "#FFFFFF", borderColor = pal$grid, borderWidth = 1,
             padding = c(10, 14),
             textStyle = list(fontFamily = ec_mono, fontSize = 16, color = pal$text))
  if (!is.null(formatter)) tt$formatter <- ec_js(formatter)
  tt
}

# Tooltip text for charts with several series: "Series: +1,234 suffix"
ec_tip_signed <- function(suffix = " cr") {
  sprintf("function (ps) {
    var h = '<b>' + String(ps[0].axisValueLabel).replace(/\\n/g, ' ') + '</b>';
    ps.forEach(function (p) {
      var v = Number(p.value);
      h += '<br/>' + p.marker + p.seriesName + ': ' + (v >= 0 ? '+' : '\\u2212') +
           Math.abs(Math.round(v)).toLocaleString('en-US') + '%s';
    });
    return h; }", suffix)
}

ec_legend <- function(names) {
  list(data = as.list(names), top = 0, left = 70, selectedMode = FALSE,
       itemWidth = 18, itemHeight = 18, itemGap = 26, icon = "roundRect",
       textStyle = list(fontFamily = ec_mono, fontSize = 17, color = pal$text))
}

ec_value_axis_title <- function(text, gap = 78) {
  list(name = text, nameLocation = "middle", nameGap = gap,
       nameTextStyle = list(fontSize = 17, fontWeight = "bold", color = pal$maroon,
                            fontFamily = ec_mono))
}

# ---------------------------------------------------------
# Waterfall: first and last values are totals, the rest are steps.
#   vals      start total, steps..., end total
#   is_total  TRUE for the totals
#   x_labels  axis labels (may contain \n)
#   tip_names full names shown in the tooltip
# ---------------------------------------------------------
ec_waterfall <- function(vals, is_total, x_labels, tip_names, y_title,
                         lo_mult = 0.8, hi_mult = 1.04,
                         legend_names = c("Total", "Adds to profit", "Reduces profit")) {
  n <- length(vals)
  from <- numeric(n); to <- numeric(n); run <- 0
  for (i in seq_len(n)) {
    if (is_total[i]) { from[i] <- 0;   to[i] <- vals[i]; run <- vals[i] }
    else             { from[i] <- run; run <- run + vals[i]; to[i] <- run }
  }
  top <- pmax(from, to); bot <- pmin(from, to)
  kind <- ifelse(is_total, "total", ifelse(vals >= 0, "up", "down"))

  base   <- ifelse(is_total, 0, bot)               # invisible lift under floating bars
  height <- ifelse(is_total, vals, top - bot)
  labs   <- ifelse(is_total, comma(vals, accuracy = 1), ec_signed(vals))

  lo <- floor(min(bot[!is_total]) * lo_mult / 1000) * 1000
  hi <- ceiling(max(top) * hi_mult / 500) * 500

  step <- function(name, k, colour) {
    list(name = name, type = "bar", stack = "wf", barWidth = "68%",
         data = as.list(ifelse(kind == k, height, 0)),
         itemStyle = list(color = colour, borderRadius = c(6, 6, 0, 0)),
         emphasis = list(disabled = TRUE))
  }
  connectors <- lapply(seq_len(n - 1), function(k) {
    list(list(coord = c(k - 1 + 0.34, to[k])), list(coord = c(k - 0.34, to[k])))
  })
  names_json <- jsonlite::toJSON(unname(tip_names), auto_unbox = FALSE)
  labs_json  <- jsonlite::toJSON(labs, auto_unbox = FALSE)

  opt <- c(ec_motion(), list(
    legend  = ec_legend(legend_names),
    grid    = list(left = 70, right = 24, top = 64, bottom = 8, containLabel = TRUE),
    tooltip = ec_tooltip("axis", sprintf(
      "function (p) { var n = %s, l = %s, i = p[0].dataIndex; return '<b>' + n[i] + '</b><br/>' + l[i] + ' cr'; }",
      names_json, labs_json)),
    xAxis = list(type = "category", data = as.list(unname(x_labels)),
                 axisTick = list(show = FALSE),
                 axisLine = list(lineStyle = list(color = pal$grid)),
                 axisLabel = list(interval = 0, fontSize = 17, lineHeight = 24, color = pal$text)),
    yAxis = c(list(type = "value", min = lo, max = hi,
                   axisLabel = list(fontSize = 16, color = pal$text,
                                    formatter = ec_js("function (v) { return v.toLocaleString('en-US'); }")),
                   splitLine = list(lineStyle = list(color = pal$grid))),
              ec_value_axis_title(y_title)),
    series = list(
      list(name = "base", type = "bar", stack = "wf", barWidth = "68%",
           data = as.list(base), silent = TRUE,
           itemStyle = list(color = "transparent"), emphasis = list(disabled = TRUE)),
      step(legend_names[1], "total", "#3D3D3D"),
      step(legend_names[2], "up",    pal$primary),
      step(legend_names[3], "down",  pal$muted),
      # invisible line that carries the value labels and the dotted connectors
      list(name = "labels", type = "line", data = as.list(top), symbol = "circle", symbolSize = 0,
           silent = TRUE, lineStyle = list(width = 0), z = 5,
           label = list(show = TRUE, position = "top", distance = 8, fontSize = 20,
                        fontWeight = "bold", color = pal$text,
                        formatter = ec_js(sprintf("function (p) { return %s[p.dataIndex]; }", labs_json))),
           markLine = list(silent = TRUE, symbol = "none", animation = FALSE,
                           lineStyle = list(type = "dotted", color = pal$muted, width = 1.5),
                           label = list(show = FALSE), data = connectors))
    )
  ))
  e_list(e_charts(), opt)
}


# ---------------------------------------------------------
# Generic bar chart (single or grouped series, vertical or horizontal).
#   x         category labels
#   series    list of list(name, color, values, labels)
#             values: numbers (NA = no bar); labels: text shown on / in the tooltip for each bar
#   stack     TRUE draws the series on top of each other (used for the funding chart)
# Negative values get their label below the bar (left of it when horizontal).
# ---------------------------------------------------------
ec_wrap <- function(x, width = 16) {
  vapply(as.character(x), function(s) paste(strwrap(s, width), collapse = "\n"), "", USE.NAMES = FALSE)
}

ec_bar_chart <- function(x, series, y_title, horizontal = FALSE, stack = FALSE,
                         label_size = 19, wrap = 16, name_gap = NULL) {
  multi <- length(series) > 1
  all_vals <- unlist(lapply(series, function(s) s$values))
  has_neg <- any(all_vals < 0, na.rm = TRUE)
  json <- function(v) jsonlite::toJSON(v, auto_unbox = FALSE, na = "null")

  pos <- function(v) if (horizontal) (if (v >= 0) "right" else "left") else (if (v >= 0) "top" else "bottom")
  items <- function(vals) lapply(vals, function(v)
    if (is.na(v)) "-" else list(value = v, label = list(position = pos(v))))

  label_js <- function(labs) ec_js(sprintf(
    "function (p) { return %s[p.dataIndex]; }", json(labs)))
  all_labs <- lapply(series, function(s) s$labels)

  ser <- lapply(seq_along(series), function(i) {
    s <- series[[i]]
    o <- list(name = s$name, type = "bar", data = items(s$values),
              barWidth = if (multi && !stack) NULL else "58%",
              itemStyle = list(color = s$color,
                               borderRadius = if (horizontal) c(0, 6, 6, 0) else c(6, 6, 0, 0)),
              emphasis = list(disabled = TRUE),
              label = list(show = TRUE, fontSize = label_size, fontWeight = "bold", color = pal$text,
                           distance = 8, lineHeight = label_size + 4, formatter = label_js(s$labels)))
    if (multi && !stack) { o$barCategoryGap <- "30%"; o$barGap <- "8%" }
    if (stack) o$stack <- "s"
    if (i == 1 && has_neg)   # zero line, drawn only when some bars go below it
      o$markLine <- list(silent = TRUE, symbol = "none", animation = FALSE,
                         lineStyle = list(color = pal$muted, width = 1.2, type = "solid"),
                         label = list(show = FALSE),
                         data = list(if (horizontal) list(xAxis = 0) else list(yAxis = 0)))
    o
  })

  cat_axis <- list(type = "category", data = as.list(ec_wrap(x, wrap)),
                   axisTick = list(show = FALSE),
                   axisLine = list(onZero = FALSE, lineStyle = list(color = pal$grid)),
                   axisLabel = list(interval = 0, fontSize = 17, lineHeight = 24, color = pal$text))
  val_axis <- list(type = "value",
                   boundaryGap = if (has_neg) c("15%", "22%") else c(0, "22%"),
                   axisLabel = list(fontSize = 16, color = pal$text,
                                    formatter = ec_js("function (v) { return v.toLocaleString('en-US'); }")),
                   splitLine = list(lineStyle = list(color = pal$grid)))
  if (!has_neg) val_axis$min <- 0
  if (horizontal) {
    val_axis <- c(val_axis, ec_value_axis_title(y_title, gap = if (is.null(name_gap)) 40 else name_gap))
  } else {
    val_axis <- c(val_axis, ec_value_axis_title(y_title, gap = if (is.null(name_gap)) 78 else name_gap))
  }

  tip <- sprintf("function (ps) {
      var L = %s;
      var h = '<b>' + String(ps[0].axisValueLabel).replace(/\\n/g, ' ') + '</b>';
      ps.forEach(function (p) {
        var t = L[p.seriesIndex][p.dataIndex];
        if (t === null || t === undefined) return;
        h += '<br/>' + p.marker + %s + String(t).replace(/\\n/g, ' ');
      });
      return h; }", json(all_labs), if (multi) "p.seriesName + ': ' + " else "''")

  opt <- c(ec_motion(), list(
    grid = list(left = if (horizontal) 36 else 70, right = 40,
                top = if (multi) 64 else 36, bottom = if (horizontal) 56 else 8, containLabel = TRUE),
    tooltip = ec_tooltip("axis", tip),
    xAxis = if (horizontal) val_axis else cat_axis,
    yAxis = if (horizontal) cat_axis else val_axis,
    series = ser
  ))
  if (multi) opt$legend <- ec_legend(vapply(series, function(s) s$name, ""))
  e_list(e_charts(), opt)
}

# Convert long data (x, group, value) into the series list used above.
ec_from_long <- function(d, colors, label_fun) {
  groups <- levels(d$group)
  lapply(groups, function(g) {
    v <- d$value[d$group == g]
    list(name = g, color = unname(colors[g]), values = v, labels = label_fun(v))
  })
}

# Replays a chart's animation each time it scrolls into view.
# Wrap an echarts4rOutput() in div(class = "replay-chart", ...) to use it.
replay_js <- "
document.addEventListener('DOMContentLoaded', function () {
  if (!('IntersectionObserver' in window)) return;
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.intersectionRatio < 0.6) return;   // only when mostly in view (not when leaving)
      var el = e.target.querySelector('.echarts4r');
      if (!el || typeof echarts === 'undefined') return;
      var inst = echarts.getInstanceByDom(el);
      if (!inst) return;
      var opt = inst.getOption();
      inst.clear();
      inst.setOption(opt);
    });
  }, { threshold: 0.6 });
  document.querySelectorAll('.replay-chart').forEach(function (w) { io.observe(w); });
});
"
