# ==========================================================
# Customer Segment Profitability Analysis - Axis Bank
# Single continuous page Shiny dashboard (skeleton)
#
# Folder layout:
#   Fin_dashboard/
#   ├── app.R
#   ├── modules/
#   │   ├── eda.R            <- EDA charts + carousel
#   │   ├── bridge.R         <- profit bridge
#   │   ├── drivers_kpis.R   <- driver breakdown + 7 KPIs
#   │   ├── segment_matrix.R <- segment comparison heat map
#   │   └── conclusion.R     <- final conclusion
#   └── Assets/
#       ├── imgs/axis_logo.png
#       └── Data/extracted_data/*.csv
# ==========================================================

library(shiny)
library(ggplot2)
library(scales)

# ---- Assets ----
# Serves Fin_dashboard/Assets/imgs/ at the URL prefix "imgs/".
# Works whether you source() the file, run it from VS Code, or use runApp():
# it finds the folder app.R lives in instead of relying on the working directory.
app_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile)),  # when run via source()
  error = function(e) getwd()                  # when run via runApp()
)
addResourcePath("imgs", file.path(app_dir, "Assets", "imgs"))

# ---- Data + EDA module ----
data_dir <- file.path(app_dir, "Assets", "Data", "extracted_data")
source(file.path(app_dir, "modules", "eda.R"), local = TRUE, encoding = "UTF-8")
source(file.path(app_dir, "modules", "echarts_helpers.R"), local = TRUE, encoding = "UTF-8")  # must come after eda.R
source(file.path(app_dir, "modules", "bridge.R"), local = TRUE, encoding = "UTF-8")  # must come after eda.R
source(file.path(app_dir, "modules", "drivers_kpis.R"), local = TRUE, encoding = "UTF-8")  # must come after eda.R
source(file.path(app_dir, "modules", "segment_matrix.R"), local = TRUE, encoding = "UTF-8")  # must come after eda.R
source(file.path(app_dir, "modules", "conclusion.R"), local = TRUE, encoding = "UTF-8")  # must come after bridge, drivers_kpis, segment_matrix

# ---- Axis Bank palette (edit here, applies everywhere) ----
axis_colors <- list(
  burgundy = "#97144D",  # primary brand colour
  maroon   = "#6B0E37",  # darker shade for gradients / depth
  white    = "#FFFFFF",
  light    = "#F7F1F4",  # soft tint for alternating sections
  text     = "#2B2B2B"
)

# ---- CSS ----
app_css <- sprintf("
@import url('https://fonts.googleapis.com/css2?family=Roboto+Mono:wght@400;500;700&display=swap');

:root {
  --axis-burgundy: %s;
  --axis-maroon:   %s;
  --axis-white:    %s;
  --axis-light:    %s;
  --axis-text:     %s;
}

html { font-size: 140%%; }  /* presentation scale: all rem text is 1.4x; hero title is compensated below */

html, body {
  margin: 0;
  padding: 0;
  font-family: 'Roboto Mono', monospace;
  color: var(--axis-text);
  background: var(--axis-white);
  scroll-behavior: smooth;
}

/* Remove Shiny's default page padding so sections run edge to edge */
.container-fluid { padding: 0 !important; }

/* ---------- HERO ---------- */
.hero {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 40px 8%%;
  background: linear-gradient(160deg, var(--axis-burgundy) 0%%, var(--axis-maroon) 100%%);
  color: var(--axis-white);
}

.hero-logo {
  display: block;
  max-width: 480px;   /* was 260px; the source image is 860px wide, so this stays sharp */
  width: 100%%;
  height: auto;
  margin: 0 auto 56px auto;
}

.hero-title {
  font-family: 'Roboto Mono', monospace;
  font-weight: 700;
  font-size: clamp(1.0714rem, 3.2vw, 2rem);  /* same 24-44.8px as before */
  line-height: 1.3;
  max-width: 1000px;
  margin: 0;
  text-align: center;
}

/* Group members under the title */
.hero-team {
  margin-top: 40px;
  font-size: 0.8rem;
}
.hero-team-label {
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  margin-bottom: 10px;
  opacity: 0.95;
}
.hero-team-grid {
  display: inline-grid;
  grid-template-columns: auto auto;
  column-gap: 20px;
  row-gap: 4px;
  line-height: 1.5;
}
.hero-team-grid .roll { text-align: right; opacity: 0.75; }
.hero-team-grid .name { text-align: left; font-weight: 500; }

/* ---------- CONTENT SECTIONS ---------- */
.dash-section {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 15vh 8%%;
}

/* Scroll fade: opacity and shift are set by JS (see scroll_js below) */
.fade-item {
  will-change: opacity, transform;
}
.dash-section:nth-of-type(even) { background: var(--axis-light); }

.section-heading {
  font-weight: 700;
  color: var(--axis-burgundy);
  border-bottom: 3px solid var(--axis-burgundy);
  display: inline-block;
  padding-bottom: 6px;
  margin-bottom: 30px;
}

.placeholder-box {
  border: 2px dashed var(--axis-burgundy);
  border-radius: 8px;
  min-height: 300px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--axis-burgundy);
  opacity: 0.6;
}

/* ---------- TEXT + CARDS ---------- */
.dash-section { gap: 15vh; }

.lead {
  font-size: 1.05rem;
  line-height: 1.8;
  max-width: 1200px;
}
.body-text {
  font-size: 0.95rem;
  line-height: 1.8;
  max-width: 1200px;
}
.sub-heading {
  font-weight: 700;
  color: var(--axis-maroon);
  margin: 0 0 6px 0;
}
.sub-note {
  margin: 0 0 24px 0;
  opacity: 0.75;
  font-size: 0.9rem;
}

.stat-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(290px, 1fr));
  gap: 20px;
}
.stat-card {
  background: var(--axis-white);
  border: 1px solid #EADDE3;
  border-radius: 22px;
  box-shadow: 0 8px 24px rgba(107, 14, 55, 0.07);
  padding: 24px 28px;
}
.stat-value {
  font-size: 1.9rem;
  font-weight: 700;
  color: var(--axis-burgundy);
}
.stat-label {
  font-weight: 500;
  margin-top: 4px;
}
.stat-note {
  font-size: 0.82rem;
  opacity: 0.75;
  margin-top: 6px;
  line-height: 1.5;
}
.stat-card.warn { border-color: #E8B4AE; }
.stat-card.warn .stat-value { color: #C0392B; }

/* Long stacked rows: value | label | note */
.stat-stack {
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-width: 1400px;
}
.stat-stack .stat-card {
  display: grid;
  grid-template-columns: minmax(180px, 0.8fr) minmax(200px, 1fr) minmax(240px, 1.6fr);
  align-items: center;
  column-gap: 32px;
  padding: 22px 36px;
}
.stat-stack .stat-value { font-size: 1.7rem; }
.stat-stack .stat-label { margin-top: 0; font-size: 1.05rem; }
.stat-stack .stat-note  { margin-top: 0; font-size: 0.9rem; }
@media (max-width: 900px) {
  .stat-stack .stat-card { grid-template-columns: 1fr; row-gap: 4px; }
}

.callout {
  background: var(--axis-burgundy);
  color: var(--axis-white);
  border-radius: 22px;
  padding: 28px 32px;
  margin-top: 24px;
  line-height: 1.8;
  max-width: 1400px;
}
.callout h4 { margin: 0 0 10px 0; font-weight: 700; }
.callout p  { margin: 0; font-size: 0.95rem; }

.product-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 20px;
}
.product-card {
  background: var(--axis-white);
  border: 1px solid #EADDE3;
  border-radius: 22px;
  box-shadow: 0 8px 24px rgba(107, 14, 55, 0.07);
  padding: 24px 28px;
}
.product-card h4 { color: var(--axis-burgundy); font-weight: 700; margin: 0 0 10px 0; }
.product-card ul { padding-left: 18px; margin: 0; line-height: 1.7; font-size: 0.9rem; }

.ratio-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(380px, 1fr));
  gap: 20px;
}
.ratio-card {
  background: var(--axis-white);
  border: 1px solid #EADDE3;
  border-radius: 22px;
  box-shadow: 0 8px 24px rgba(107, 14, 55, 0.07);
  padding: 26px 30px;
}
.ratio-card h4 { color: var(--axis-maroon); font-weight: 700; margin: 0 0 4px 0; }
.ratio-card .stat-value { margin-bottom: 2px; }
.ratio-card p { font-size: 0.88rem; line-height: 1.7; margin: 10px 0 0 0; }
.ratio-card .tag {
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--axis-burgundy);
  display: block;
  margin-top: 14px;
}
",
  axis_colors$burgundy, axis_colors$maroon, axis_colors$white,
  axis_colors$light, axis_colors$text
)

# ---- Carousel CSS + JS ----
carousel_css <- "
.carousel { width: 100%; }
.carousel-viewport { overflow: hidden; border-radius: 24px; }
.carousel-track {
  display: flex;
  transition: transform 0.55s cubic-bezier(0.22, 0.61, 0.36, 1);
  will-change: transform;
}
.carousel-slide { flex: 0 0 100%; min-width: 0; box-sizing: border-box; padding: 4px; }
.slide-card {
  background: #FFFFFF;
  border: 1px solid #EADDE3;
  border-radius: 22px;
  padding: 22px 28px 18px 28px;
  box-shadow: 0 8px 24px rgba(107, 14, 55, 0.07);
}
.slide-title {
  margin: 0 0 8px 0;
  font-weight: 700;
  font-size: 1.25rem;
  color: var(--axis-maroon);
}
.slide-card .shiny-plot-output { min-height: 300px; }
.slide-takeaway {
  margin: 12px 0 0 0;
  font-size: 0.9rem;
  line-height: 1.7;
  max-width: 1300px;
}
.slide-takeaway .tag {
  display: inline-block;
  margin-right: 10px;
  padding: 1px 8px;
  border-radius: 4px;
  background: var(--axis-burgundy);
  color: #FFFFFF;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}
.carousel-controls {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 18px;
  margin-top: 18px;
}
.carousel-btn {
  width: 46px;
  height: 46px;
  border-radius: 50%;
  border: 2px solid var(--axis-burgundy);
  background: transparent;
  color: var(--axis-burgundy);
  font-size: 1.1rem;
  cursor: pointer;
  transition: background 0.2s, color 0.2s;
}
.carousel-btn:hover, .carousel-btn:focus-visible {
  background: var(--axis-burgundy);
  color: #FFFFFF;
  outline: none;
}
.carousel-dots { display: flex; gap: 10px; flex-wrap: wrap; justify-content: center; }
.dot {
  width: 12px;
  height: 12px;
  padding: 0;
  border-radius: 50%;
  border: 2px solid var(--axis-burgundy);
  background: transparent;
  cursor: pointer;
  transition: background 0.2s, transform 0.2s;
}
.dot.active { background: var(--axis-burgundy); transform: scale(1.25); }
.carousel-counter { font-size: 0.85rem; font-weight: 500; color: var(--axis-maroon); min-width: 64px; text-align: center; }
"

carousel_js <- "
(function () {
  function init() {
    var root = document.getElementById('eda-carousel');
    var track = document.getElementById('eda-track');
    if (!root || !track) return;

    var total = track.children.length;
    var dots = Array.prototype.slice.call(root.querySelectorAll('.dot'));
    var counter = document.getElementById('eda-counter');
    var idx = 0;

    function go(i) {
      idx = (i + total) % total;                      // wraps around at both ends
      track.style.transform = 'translateX(-' + (idx * 100) + '%)';
      dots.forEach(function (d, k) { d.classList.toggle('active', k === idx); });
      counter.textContent = (idx + 1) + ' / ' + total;
    }

    document.getElementById('eda-prev').addEventListener('click', function () { go(idx - 1); });
    document.getElementById('eda-next').addEventListener('click', function () { go(idx + 1); });
    dots.forEach(function (d) {
      d.addEventListener('click', function () { go(parseInt(d.getAttribute('data-index'), 10)); });
    });

    // Left/right arrow keys, only while the carousel is on screen
    document.addEventListener('keydown', function (e) {
      if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return;
      var r = root.getBoundingClientRect();
      if (r.bottom < 0 || r.top > window.innerHeight) return;
      e.preventDefault();
      go(idx + (e.key === 'ArrowRight' ? 1 : -1));
    });

    // Swipe on touch screens
    var startX = null;
    root.addEventListener('touchstart', function (e) { startX = e.touches[0].clientX; }, { passive: true });
    root.addEventListener('touchend', function (e) {
      if (startX === null) return;
      var dx = e.changedTouches[0].clientX - startX;
      if (Math.abs(dx) > 50) go(idx + (dx < 0 ? 1 : -1));
      startX = null;
    });

    go(0);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
"

# ---- Small UI helpers ----
stat_card <- function(value, label, note = NULL, warn = FALSE) {
  div(class = if (warn) "stat-card warn" else "stat-card",
    div(class = "stat-value", value),
    div(class = "stat-label", label),
    if (!is.null(note)) div(class = "stat-note", note)
  )
}

product_card <- function(title, items) {
  div(class = "product-card",
    h4(title),
    tags$ul(lapply(items, tags$li))
  )
}

ratio_card <- function(name, value, change, what, says) {
  div(class = "ratio-card",
    h4(name),
    div(class = "stat-value", value),
    div(class = "stat-note", change),
    span(class = "tag", "What it is"),
    p(what),
    span(class = "tag", "What it says"),
    p(says)
  )
}

# ---- Scroll fade JS ----
# Every element with class "fade-item" is fully visible when its centre is at
# the middle of the screen. Content arriving from below fades in over a short
# distance (quick); content leaving through the top fades out over a longer
# distance and never drops below MIN_OPACITY (gentle). Both drift a little.
scroll_js <- "
(function () {
  var FADE_IN_RANGE  = 0.8;   // screen heights over which content fades IN  (bigger = quicker to appear)
  var FADE_OUT_RANGE = 1.0;   // screen heights over which content fades OUT (bigger = slower to vanish)
  var MIN_OPACITY    = 0.2;   // faintest an element gets (0 = fully invisible)
  var DRIFT_PX       = 40;    // max vertical drift in pixels

  function update() {
    var vh = window.innerHeight;
    document.querySelectorAll('.fade-item').forEach(function (el) {
      var r = el.getBoundingClientRect();
      var offset = (r.top + r.height / 2) - vh / 2;       // + below centre (arriving), - above (leaving)
      var range = offset > 0 ? FADE_IN_RANGE : FADE_OUT_RANGE;
      var t = Math.min(Math.abs(offset) / (vh * range), 1);
      var eased = MIN_OPACITY + (1 - MIN_OPACITY) * (1 - t * t);   // gentle ease
      el.style.opacity = eased;
      el.style.transform = 'translateY(' + (Math.sign(offset) * t * DRIFT_PX) + 'px)';
    });
  }

  var ticking = false;
  function onScroll() {
    if (!ticking) {
      ticking = true;
      requestAnimationFrame(function () { update(); ticking = false; });
    }
  }

  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', onScroll);
  window.addEventListener('load', update);
  document.addEventListener('shiny:value', function () { setTimeout(update, 50); });
  update();
})();
"

# ---- News headline marquee ----
# A continuous right-to-left slider of newspaper screenshots. Drop image files
# (png, jpg, webp, gif) into Assets/imgs/news/ and they appear automatically,
# in alphabetical order, so name them 01_..., 02_... to control the order.
# With no images in the folder, placeholder cards are shown instead.
news_dir   <- file.path(app_dir, "Assets", "imgs", "news")
news_files <- sort(list.files(news_dir, pattern = "\\.(png|jpe?g|webp|gif)$", ignore.case = TRUE))

news_css <- "
.news-marquee {
  overflow: hidden;
  padding: 14px 0 22px 0;
  -webkit-mask-image: linear-gradient(to right, transparent 0, #000 6%, #000 94%, transparent 100%);
  mask-image: linear-gradient(to right, transparent 0, #000 6%, #000 94%, transparent 100%);
}
.news-track {
  display: flex;
  width: max-content;
  animation: newsScroll var(--news-dur, 60s) linear infinite;
}
.news-marquee:hover .news-track { animation-play-state: paused; }   /* pause while the mouse is over it */
.news-half { display: flex; flex: 0 0 auto; }
.news-item { flex: 0 0 auto; margin-right: 32px; }
.news-item img {
  display: block;
  height: 30vh;              /* image height; width follows each screenshot's shape */
  width: auto;
  background: #FFFFFF;
  border: 1px solid #EADDE3;
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(107, 14, 55, 0.12);
}
.news-ph {
  height: 30vh;
  width: 42vh;
  box-sizing: border-box;
  padding: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  font-size: 0.85rem;
  line-height: 1.5;
  color: var(--axis-burgundy);
  border: 2px dashed var(--axis-burgundy);
  border-radius: 12px;
  opacity: 0.6;
}
@keyframes newsScroll {
  from { transform: translateX(0); }
  to   { transform: translateX(-50%); }   /* one full set, so the loop has no visible jump */
}
@media (prefers-reduced-motion: reduce) {
  .news-track { animation: none; }
  .news-marquee { overflow-x: auto; -webkit-mask-image: none; mask-image: none; }
}
"

# secs_per_item sets the speed: bigger = slower
news_marquee_ui <- function(files = news_files, secs_per_item = 6) {
  items <- if (length(files) > 0) {
    lapply(files, function(f)
      div(class = "news-item",
          img(src = paste0("imgs/news/", utils::URLencode(f, reserved = TRUE)),
              alt = tools::file_path_sans_ext(f))))
  } else {
    lapply(1:6, function(i)
      div(class = "news-item",
          div(class = "news-ph", paste0("Headline screenshot ", i, " (add images to Assets/imgs/news/)"))))
  }
  # repeat short lists so one set is wider than the screen, then show the set twice
  one_set <- rep(items, max(1, ceiling(8 / length(items))))
  div(class = "news-marquee",
    div(class = "news-track", style = sprintf("--news-dur:%ds;", length(one_set) * secs_per_item),
      div(class = "news-half", one_set),
      div(class = "news-half", `aria-hidden` = "true", one_set)
    )
  )
}

# ---- UI (no navbar: a plain fluidPage, one continuous scroll) ----
ui <- fluidPage(
  title = "Axis Bank | Customer Segment Profitability",
  tags$head(
    tags$style(HTML(app_css)),
    tags$style(HTML(carousel_css)),
    tags$style(HTML(news_css)),
    tags$style(HTML(bridge_css)),
    tags$script(HTML(replay_js)),
    tags$style(HTML(dk_css)),
    tags$style(HTML(sm_css)),
    tags$script(HTML(sm_js)),
    tags$script(HTML(scroll_js)),
    tags$script(HTML(carousel_js))
  ),

  # Hero
  div(class = "hero",
    div(class = "fade-item",
      img(src = "imgs/axis_logo.png", class = "hero-logo", alt = "Axis Bank logo"),
      h1(class = "hero-title",
         "Customer Segment Profitability analysis based on loan given, credit given, and CASA deposit"),
      div(class = "hero-team",
        div(class = "hero-team-label", "Group 4"),
        div(class = "hero-team-grid",
          # edit here to change names / roll numbers
          lapply(list(c("25060242153", "Teerth"),
                      c("25060242127", "Sherin"),
                      c("25060242061", "Devashish"),
                      c("25060242025", "Aparna"),
                      c("25060242136", "Smitashree")),
                 function(m) tagList(span(class = "roll", m[1]), span(class = "name", m[2])))
        )
      )
    )
  ),

  # ======================= SECTION 1: ABOUT AXIS BANK =======================
  div(class = "dash-section",

    # 1a. Intro
    div(class = "fade-item",
      h2(class = "section-heading", "About Axis Bank"),
      p(class = "lead",
        "Axis Bank was established in 1993 as UTI Bank and is now the third largest private sector bank in India, after HDFC Bank and ICICI Bank. It has the third largest branch network among private banks and operates internationally from DIFC (Dubai), Singapore and GIFT City."),
      p(class = "body-text",
        "In 2023 it acquired Citibank India's consumer business, its biggest strategic acquisition in recent years. The deal brought in affluent customers and a strong credit card base, which helps explain Axis's position in credit cards today.")
    ),

    # 1a-2. News headlines (sliding carousel; screenshots go in Assets/imgs/news/)
    div(class = "fade-item",
      h3(class = "sub-heading", "In the news"),
      p(class = "sub-note", "Recent press coverage of Axis Bank."),
      news_marquee_ui()
    ),

    # 1b. Market snapshot
    div(class = "fade-item",
      h3(class = "sub-heading", "Market snapshot"),
      p(class = "sub-note", "Axis Bank is part of the Nifty 50. Figures as at the end of the June 2026 quarter."),
      div(class = "stat-stack",
        stat_card("\u20B91,328", "Share price on NSE", "Just before results"),
        stat_card("~15.7x", "Price to earnings", "HDFC Bank 16.6x \u00B7 ICICI Bank 19.1x \u00B7 Kotak Bank 20.1x"),
        stat_card("~2.0x", "Price to book value"),
        stat_card("16.67%", "Capital adequacy ratio"),
        stat_card("14.64%", "CET-1 ratio")
      ),
      div(class = "callout",
        p("Both capital ratios sit far above regulatory requirements. The valuation discount to peers is partly about profitability: Axis's returns remain lower than ICICI Bank's.")
      )
    ),

    # 1c. Q1 FY27 performance + margin story
    div(class = "fade-item",
      h3(class = "sub-heading", "Q1 FY27 performance"),
      p(class = "sub-note", "Profit has risen steadily, but margins are under strain."),
      div(class = "stat-stack",
        stat_card("\u20B97,114 cr", "Standalone net profit", "Up 23% from \u20B95,806 cr a year ago"),
        stat_card("\u20B914,646 cr", "Net interest income", "Up 8%"),
        stat_card("\u20B911,122 cr", "Core operating profit", "Up 10%"),
        stat_card("3.46%", "Net interest margin", "Narrowed from 3.80% a year ago", warn = TRUE),
        stat_card("38.0%", "CASA ratio (month-end)", "Down from 40.3% a year ago", warn = TRUE)
      ),
      div(class = "callout",
        h4("Why the margin matters for this study"),
        p("Loans grew faster than cheap funding. Net advances rose 19% to \u20B912.6 lakh crore, while CASA deposits grew only 11.4% and term deposits grew 22.8%. The month-end CASA ratio fell to 38.0% from 40.3% a year ago, its lowest level since Q1 2017. In effect, Axis is funding more of its lending at a higher cost. That is why a customer who holds a loan, a credit card and a CASA balance is far more profitable than one who borrows without keeping deposits.")
      )
    ),

    # 1d. Asset quality
    div(class = "fade-item",
      h3(class = "sub-heading", "Asset quality"),
      p(class = "sub-note", "A bright spot: fewer defaults mean less of each customer's income is lost to bad loans."),
      div(class = "stat-grid",
        stat_card("1.28%", "Gross NPA"),
        stat_card("0.39%", "Net NPA"),
        stat_card("0.63%", "Net credit cost")
      )
    ),

    # 1e. What Axis sells
    div(class = "fade-item",
      h3(class = "sub-heading", "What Axis sells"),
      p(class = "sub-note", "Four product families feed the earnings pool."),
      div(class = "product-grid",
        product_card("Retail loans", c(
          "Home loans", "Personal loans", "Auto and two-wheeler loans",
          "Loans against property", "Gold loans", "Education loans", "Loans against securities")),
        product_card("Business and corporate", c(
          "Working capital", "Term loans", "MSME credit",
          "Corporate advances up 38% year on year in Q1 FY27")),
        product_card("Credit cards", c(
          "Flipkart, Ace, Airtel, Magnus and Reserve, from mass to premium",
          "0.92 million new cards issued in Q1 FY27",
          "13.4% share of cards in force")),
        product_card("Non-bank arms", c(
          "Axis Finance profit of \u20B9244 cr, up 29%"))
      ),
      div(class = "callout",
        p("Axis earns from three main sources: loan interest, card fees and low-cost CASA funds. To see where the bank really makes money, we need to know which types of customer use which of these services.")
      )
    )
  ),

  # ======================= SECTION 2: READING THE RATIOS =======================
  div(class = "dash-section",

    # 2a. Two ratio cards
    div(class = "fade-item",
      h2(class = "section-heading", "Reading the Ratios"),
      p(class = "lead",
        "Two ratios show how falling interest rates are hitting income. Yield figures are approximate."),
      div(class = "ratio-grid",
        ratio_card(
          "Yield on advances", "8.41%", "\u25BC 0.80 pt from 9.21% a year ago",
          "The interest the bank earns on its loans, which are its main source of income.",
          "The drop comes from repo-rate cuts. About 74% of the loan book is floating-rate, so lower policy rates reach borrowers quickly. Falling yields squeeze income per loan, so the bank must grow its loan book to hold profit steady. What matters is how fast funding costs fall to match: cost of funds fell 0.41 points (5.21% to 4.80%), so loan yields fell about twice as fast."
        ),
        ratio_card(
          "Yield on investments", "6.10%", "\u25BC 0.71 pt from 6.81% a year ago",
          "What the bank earns on bonds and other securities, where it parks deposits it has not lent out.",
          "The lower figure reflects market conditions. Rising market yields mean lower bond prices and so fewer trading gains, which ties back to the profit bridge, where trading income was a drag on profit."
        )
      )
    ),

    # 2b. Verdict
    div(class = "fade-item",
      div(class = "callout",
        h4("Overall"),
        p("Axis is a strong third among private banks. It is competitive but not the leader on returns. Income is falling on both sides of the balance sheet, loans and investments. Both falls are largely rate-driven, so they show the whole sector's squeeze more than an Axis-specific weakness.")
      )
    )
  ),

  # ======================= SECTION 3: EDA CAROUSEL =======================
  div(class = "dash-section",
    div(class = "fade-item",
      h2(class = "section-heading", "Exploratory Data Analysis"),
      p(class = "lead",
        "Nine charts on segment profit, growth, funding and asset quality. Use the arrows, the dots or the left and right keys to move between them."),
      eda_carousel_ui()
    )
  ),

  # ======================= SECTION 4: PROFIT BRIDGE =======================
  div(class = "dash-section",
    bridge_ui()
  ),

  # ======================= SECTION 5: DRIVER BREAKDOWN =======================
  div(class = "dash-section",
    drivers_ui()
  ),

  # ======================= SECTION 6: SEVEN KPIs =======================
  div(class = "dash-section",
    kpis_ui()
  ),

  # ======================= SECTION 7: SEGMENT COMPARISON MATRIX =======================
  div(class = "dash-section",
    segment_matrix_ui()
  ),

  # ======================= SECTION 8: CONCLUSION =======================
  div(class = "dash-section",
    conclusion_ui()
  )
)

# ---- Server ----
server <- function(input, output, session) {
  eda_server(output)
  bridge_server(output)
  drivers_kpis_server(output)
  segment_matrix_server(output)
}

shinyApp(ui, server)

