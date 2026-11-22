# AGENT.md

Standing instructions for any agent working in this folder.

## Project
Logistic regression analysis of in-hospital stroke fatality.
- Data: `stroke-fatality-cooked2.dta` (226 rows, 22 columns; Stata format). `stroke-fatality.csv` is a raw copy and is NOT the primary source.
- Outcome: `outcome` (1 = dead at discharge, 0 = alive).
- Predictors: sex, gcs, sbp, dbp, hr, hb, plat, wbc, na, potas, cbs, urea, age, hypertension, maritalstat, malay, diabetes, dyslipidaemia, referralcase, stroketype. `rn` is a patient ID (never a predictor).

## Workflow: RREAAAPP
1. **R**esearch question: which variables are associated with in-hospital death after stroke?
2. **R**ead data: `haven::read_dta()`, then clean names (`janitor::clean_names()`), convert labelled vars with `haven::as_factor()` / `labelled` handling.
3. **E**xplore: outliers, implausible values, missing data. Numeric: histogram + boxplot. Categorical: bar chart. Use tidyverse + gtsummary.
4. **A**ssumptions: binary outcome (binomial), linearity in the logit for numeric predictors, correct model specification, no multicollinearity, adequate events per variable.
5. **A**nalyse: univariable logistic regression, select candidates, multivariable logistic regression (no interaction terms).
6. **A**ssess model: goodness of fit (Hosmer-Lemeshow), diagnostics (leverage, dbeta, dchisq), AUC/ROC, classification accuracy.
7. **P**resent: tables of log odds (B), odds ratios, 95% CI, p-values for univariable and multivariable models.
8. **P**ublish/Report: a reproducible Quarto/R Markdown or script output.

## Conventions
- Language: R. Packages: haven, tidyverse, janitor, gtsummary, gt, broom, pROC, ResourceSelection (all installed). `car` and `naniar` are NOT installed; do not rely on them without asking (base R / `broom` / `gtsummary::tbl_summary` can cover missingness and VIF alternatives).
- Never modify the original `.dta` or `.csv`. Write cleaned data to `output/` or `data/clean/`.
- Layout: `R/` scripts numbered in order (01_read_clean.R, 02_explore.R, ...), `output/figures/`, `output/tables/`.
- Use `set.seed()` where randomness is involved. Keep code readable and commented with the RREAAAPP stage.
- Report numbers faithfully; flag data problems rather than silently fixing them. Record every cleaning decision in `output/cleaning_log.md`.
- Clinical plausibility ranges must be confirmed with the user before values are altered or set to NA.
- Ask before installing packages or deleting files.
