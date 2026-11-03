# ==============================================================================
# Healthcare Operations & Claims Intelligence
# Script: generate_dashboard_charts.R
# Purpose: Generate publication-quality healthcare operations dashboard visuals
#          using R, ggplot2, and tidyverse.
# Compliance: 100% De-identified, HIPAA Safe Harbor, Aggregated Spend Only (N >> 11)
# ==============================================================================

suppressPackageStartupMessages({
  if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
  if (!requireNamespace("scales", quietly = TRUE)) install.packages("scales")
  library(tidyverse)
  library(scales)
})

# Setup Paths
args <- commandArgs(trailingOnly = FALSE)
script_dir <- tryCatch({
  dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
}, error = function(e) ".")

base_dir <- if (dir.exists(file.path(script_dir, "..", "assets"))) normalizePath(file.path(script_dir, "..")) else "."
assets_dir <- file.path(base_dir, "assets")
data_dir   <- file.path(base_dir, "data")

if (!dir.exists(assets_dir)) dir.create(assets_dir, recursive = TRUE)
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# Authentic RStudio ggplot2 Publication Theme (Light Theme)
theme_healthcare_r <- function() {
  theme_minimal(base_family = "sans") +
    theme(
      plot.background = element_rect(fill = "#FFFFFF", color = NA),
      panel.background = element_rect(fill = "#F8FAFC", color = "#CBD5E1", linewidth = 0.8),
      panel.grid.major = element_line(color = "#E2E8F0", linewidth = 0.5),
      panel.grid.minor = element_blank(),
      plot.title = element_text(color = "#1A202C", size = 12.5, face = "bold", hjust = 0, margin = margin(b = 12)),
      plot.subtitle = element_text(color = "#4A5568", size = 9.5, hjust = 0, margin = margin(b = 10)),
      axis.title = element_text(color = "#4A5568", size = 10, face = "bold"),
      axis.text = element_text(color = "#1A202C", size = 9),
      legend.background = element_rect(fill = "#FFFFFF", color = "#CBD5E1", linewidth = 0.5),
      legend.text = element_text(color = "#1A202C", size = 9),
      legend.title = element_blank(),
      plot.caption = element_text(color = "#A0AEC0", size = 8, hjust = 1, face = "italic", margin = margin(t = 8)),
      plot.margin = margin(16, 16, 16, 16)
    )
}

# ------------------------------------------------------------------------------
# 1. Payer Claims Reimbursement Profiling (All-Payer Inpatient Spend)
# ------------------------------------------------------------------------------
cat("1. Generating Chart 1: Payer Claims Reimbursement...\n")

claims_summary <- tibble(
  MDC_Category = c(
    "Musculoskeletal (MSK)", "Heart & Circulatory", "Respiratory",
    "Digestive", "Brain & Nervous System (CNS)", "Infection"
  ),
  Commercial = c(88, 54, 24, 32, 38, 18),
  Medicare_FFS = c(146, 136, 78, 63, 57, 61),
  Medicaid = c(30, 15, 22, 14, 14, 14)
)

write_csv(claims_summary, file.path(data_dir, "aggregated_payer_claims_summary.csv"))

claims_long <- claims_summary %>%
  pivot_longer(cols = c(Commercial, Medicare_FFS, Medicaid), names_to = "Payer", values_to = "Spend_Millions") %>%
  mutate(
    Payer_Label = case_when(
      Payer == "Commercial" ~ "Commercial (BCBS & Managed Care)",
      Payer == "Medicare_FFS" ~ "Medicare (Fee-For-Service)",
      Payer == "Medicaid" ~ "Medicaid"
    ),
    MDC_Category = factor(MDC_Category, levels = claims_summary$MDC_Category)
  )

p1 <- ggplot(claims_long, aes(x = MDC_Category, y = Spend_Millions, fill = Payer_Label)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.68, color = "#CBD5E1", linewidth = 0.5) +
  scale_fill_manual(values = c("Commercial (BCBS & Managed Care)" = "#3182CE", "Medicare (Fee-For-Service)" = "#38A169", "Medicaid" = "#DD6B20")) +
  scale_y_continuous(labels = dollar_format(suffix = "M"), limits = c(0, 175), expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = "All-Payer Claims Profiling: Inpatient Spend Across Top Major Diagnostic Categories",
    subtitle = "State Inpatient Database (APCD) | Zero PHI Summary (All N >> 11)",
    x = NULL,
    y = "Total Inpatient Billed Charges ($ Millions)",
    caption = "Source: Vermont All-Payer Inpatient Claims Database | Generated via R/ggplot2"
  ) +
  theme_healthcare_r() +
  theme(axis.text.x = element_text(angle = 10, hjust = 1, vjust = 1))

ggsave(file.path(assets_dir, "01_payer_claims_reimbursement.png"), plot = p1, width = 10.5, height = 5.6, dpi = 300)

# ------------------------------------------------------------------------------
# 2. Prior Authorization Lead Time & Documentation Lag
# ------------------------------------------------------------------------------
cat("2. Generating Chart 2: Prior Authorization Lead Time...\n")

pa_data <- tibble(
  Stage = factor(c(
    "Target To-Be Process\n(With Pre-Assembly & Intake Support)",
    "Standard Practice\n(Same-Day Documentation)",
    "Batch-Charting Clinicians\n(3-5 Day Charting Lag)",
    "As-Is Full Prior Auth Cycle\n(Provider Network Baseline)"
  ), levels = rev(c(
    "Target To-Be Process\n(With Pre-Assembly & Intake Support)",
    "Standard Practice\n(Same-Day Documentation)",
    "Batch-Charting Clinicians\n(3-5 Day Charting Lag)",
    "As-Is Full Prior Auth Cycle\n(Provider Network Baseline)"
  ))),
  Days = c(0.25, 0.5, 4.2, 5.2),
  Label = c("< 4 hours (5h)", "< 4 hours (12h)", "4.2 days", "5.2 days"),
  Bar_Color = c("#3182CE", "#38A169", "#E53E3E", "#DD6B20")
)

p2 <- ggplot(pa_data, aes(x = Days, y = Stage, fill = Bar_Color)) +
  geom_col(width = 0.52, color = "#CBD5E1", linewidth = 0.5) +
  scale_fill_identity() +
  geom_text(aes(label = Label), hjust = -0.15, color = "#1A202C", fontface = "bold", size = 3.5) +
  scale_x_continuous(limits = c(0, 6.2), breaks = seq(0, 6, by = 1), expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = "Prior Authorization Lead Time: Upstream Documentation Lag vs. Optimized Target",
    x = "Elapsed Time (Days to Prior Authorization Submission)",
    y = NULL,
    caption = "Operational Process Analysis | Generated via R/ggplot2"
  ) +
  theme_healthcare_r()

ggsave(file.path(assets_dir, "02_prior_auth_turnaround_lag.png"), plot = p2, width = 10.5, height = 5.2, dpi = 300)

# ------------------------------------------------------------------------------
# 3. Continuous Improvement & Operational Triage Framework
# ------------------------------------------------------------------------------
cat("3. Generating Chart 3: Operational Triage Framework...\n")

triage_data <- tibble(
  Initiative = c(
    "Consolidate Records Inboxes & Define Ownership",
    "Automated Conversational Patient Outreach (No-Shows)",
    "Clinical Documentation Intake Support (Ambient Scribing)",
    "Referral Funnel & 48-Hour SLA Tracking",
    "Prior Auth Pre-Assembly & Medical Necessity Drafter",
    "EHR Collaborative Status Queue (Sunset Shadow Excel)",
    "Fully Autonomous RPA Payer Portal Submission Bots"
  ),
  Score = c(15.00, 12.50, 10.00, 6.00, 6.00, 4.50, 1.60),
  Bar_Color = c("#38A169", "#3182CE", "#805AD5", "#38A169", "#3182CE", "#DD6B20", "#E53E3E")
) %>%
  mutate(Initiative = factor(Initiative, levels = rev(Initiative)))

p3 <- ggplot(triage_data, aes(x = Score, y = Initiative, fill = Bar_Color)) +
  geom_col(width = 0.54, color = "#CBD5E1", linewidth = 0.5) +
  scale_fill_identity() +
  geom_text(aes(label = sprintf("%.2f", Score)), hjust = -0.2, color = "#1A202C", fontface = "bold", size = 3.5) +
  scale_x_continuous(limits = c(0, 17.5), breaks = seq(0, 18, by = 3), expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = "Operational Triage Framework: Continuous Improvement Priority Ranking",
    x = "Priority Score = (Capacity Impact × Feasibility) / Operational Risk",
    y = NULL,
    caption = "Continuous Improvement Matrix | Generated via R/ggplot2"
  ) +
  theme_healthcare_r()

ggsave(file.path(assets_dir, "03_continuous_improvement_triage.png"), plot = p3, width = 10.5, height = 5.5, dpi = 300)

# ------------------------------------------------------------------------------
# 4. Claim Denial Taxonomy & Appeal Overturn Analysis
# ------------------------------------------------------------------------------
cat("4. Generating Chart 4: Claim Denial Taxonomy...\n")

denial_data <- tibble(
  Denial_Code = c(
    "CARC 197 (Precert/PA Absent)",
    "CARC 50 (Medical Necessity)",
    "CARC 16 (Missing Documentation)",
    "CARC 39 (Step Therapy Failed)",
    "CARC 27 (Coverage Terminated)"
  ),
  Share_of_Total_Denials = c(34.2, 26.8, 18.5, 12.4, 8.1),
  Appeal_Overturn_Rate = c(78.4, 62.1, 84.0, 54.2, 41.0)
)

denial_long <- denial_data %>%
  pivot_longer(cols = c(Share_of_Total_Denials, Appeal_Overturn_Rate), names_to = "Metric", values_to = "Percentage") %>%
  mutate(
    Metric_Label = if_else(Metric == "Share_of_Total_Denials", "Share of Total Denials (%)", "Appeal Overturn Success Rate (%)"),
    Denial_Code = factor(Denial_Code, levels = rev(denial_data$Denial_Code))
  )

p4 <- ggplot(denial_long, aes(x = Percentage, y = Denial_Code, fill = Metric_Label)) +
  geom_col(position = position_dodge(width = 0.72), width = 0.65, color = "#CBD5E1", linewidth = 0.5) +
  scale_fill_manual(values = c("Share of Total Denials (%)" = "#E53E3E", "Appeal Overturn Success Rate (%)" = "#3182CE")) +
  scale_x_continuous(labels = percent_format(scale = 1), limits = c(0, 100), expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = "Payer Claim Denial Taxonomy: Root Causes vs. Appeal Overturn Potential",
    x = "Percentage (%)",
    y = NULL,
    caption = "Payer Denial & Overturn Analytics | Generated via R/ggplot2"
  ) +
  theme_healthcare_r() +
  theme(legend.position = "bottom")

ggsave(file.path(assets_dir, "04_claim_denial_waterfall.png"), plot = p4, width = 10.5, height = 5.2, dpi = 300)

cat("\nSUCCESS: All 4 healthcare dashboard charts generated with authentic R/ggplot2 styling!\n")
