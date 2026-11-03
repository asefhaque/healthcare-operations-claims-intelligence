# ==============================================================================
# Healthcare Operations & Payer Claims Intelligence
# Script: 01_claims_payer_cross_tabulation.R
# Purpose: Clean, map, and summarize All-Payer Inpatient Claims data by
#          Major Diagnostic Category (MDC) and Payer Classification.
# Compliance: 100% De-identified, HIPAA Safe Harbor, Aggregated Spend Only (N >> 11)
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
})

# 1. Load Aggregated Diagnostic-to-Payer Inpatient Spend Data
# Source: State All-Payer Claims Database (APCD) Summary
claims_summary <- read_csv("../data/aggregated_payer_claims_summary.csv", show_col_types = FALSE)

cat("=== All-Payer Claims Spending Summary (Top Diagnostic Categories) ===\n")
print(claims_summary)

# 2. Reshape & Calculate Relative Payer Market Shares
claims_long <- claims_summary %>%
  pivot_longer(
    cols = c(Commercial_Payers_Millions, Medicare_FFS_Millions, Medicaid_Millions),
    names_to = "Payer_Type",
    values_to = "Spend_Millions"
  ) %>%
  mutate(
    Payer_Label = case_when(
      Payer_Type == "Commercial_Payers_Millions" ~ "Commercial (BCBS & Managed Care)",
      Payer_Type == "Medicare_FFS_Millions" ~ "Medicare (Fee-For-Service)",
      Payer_Type == "Medicaid_Millions" ~ "Medicaid"
    )
  )

# 3. Compute Category-Level Spend & Commercial-to-Government Ratios
category_analysis <- claims_long %>%
  group_by(MDC_Category) %>%
  summarize(
    Total_Inpatient_Spend_M = sum(Spend_Millions),
    Commercial_Spend_M = sum(Spend_Millions[Payer_Type == "Commercial_Payers_Millions"]),
    Government_Spend_M = sum(Spend_Millions[Payer_Type != "Commercial_Payers_Millions"]),
    Commercial_Share_Pct = round((Commercial_Spend_M / Total_Inpatient_Spend_M) * 100, 1)
  ) %>%
  arrange(desc(Total_Inpatient_Spend_M))

cat("\n=== Diagnostic Category Spending & Commercial Share Distribution ===\n")
print(category_analysis)

cat("\nAnalysis complete. Deliverable ready for continuous improvement reporting.\n")
