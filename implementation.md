# implementation.md: Plan (NOT YET EXECUTED)

Status: draft, awaiting answers to open questions at the bottom.

## Data observed (metadata only)
- File found: `stroke-fatality-cooked2.dta` (the request said `cooked.dta`; assumed same file). 226 obs x 22 vars.
- Labelled (Stata) vars: sex (1/2), outcome (0/1), hypertension, maritalstat, malay, diabetes, dyslipidaemia, referralcase, stroketype (0/1/2).
- Numeric: age, gcs, sbp, dbp, hr, hb, plat, wbc, na, potas, cbs, urea.
- Names are mostly already lower-case; `clean_names()` will still be applied. Note `referralcase` label says "missing" is folded into category 1.

## Stage 1: Read (R)
- `01_read_clean.R`: `read_dta()` -> `clean_names()` -> convert labelled vars to factors with meaningful labels (e.g. sex 1/2 needs a confirmed coding; outcome: 0 = Alive, 1 = Dead). Keep `rn` as ID.
- Save cleaned RDS to `data/clean/stroke_clean.rds`.

## Stage 2: Explore (E)
- `02_explore.R`:
  - Missingness: counts and % per variable (gtsummary / tidyverse), missingness pattern table.
  - Numeric: histogram + boxplot for each of the 12 numeric variables (faceted, saved to `output/figures/`).
  - Categorical: bar charts for each factor, including outcome.
  - Possible data-entry errors: check ranges (e.g. GCS must be 3-15, dbp < sbp, implausible hb/plat/wbc/na/potas/cbs/urea/age), duplicate IDs, unexpected category codes (e.g. stroketype = 2 "Other" frequency).
  - `tbl_summary(by = outcome)` with p-values as a descriptive table (Table 1).
  - Outliers: IQR rule + clinical plausibility; list flagged rows in `output/tables/flagged_values.csv`; no change without user decision.

## Stage 3: Assumptions (A)
- Binary outcome, independent observations: confirmed by design (state as assumption).
- Events per variable: count deaths vs number of parameters; warn if < 10 EPV.
- Linearity in the logit: for each numeric predictor, Box-Tidwell-style test (add x*log(x) term) and/or binned/lowess logit plots; fallback = categorise or add polynomial/spline if violated.
- Multicollinearity: correlation matrix of numeric vars (sbp/dbp likely correlated); VIF computed manually from `1/(1-R2)` or via `performance` if user allows installing it.
- Model specification: link test (add squared linear predictor), compare with/without omitted-variable candidates.

## Stage 4: Analyse (A)
- Univariable logistic regression: `glm(outcome ~ x, family = binomial)` for each of the 20 predictors; `gtsummary::tbl_uvregression()` giving B (log odds), OR, 95% CI, p.
- Variable selection for multivariable model: p < 0.25 (Hosmer-Lemeshow purposeful selection) from univariable, plus clinically important variables. Then manual/backward refinement with LR tests. No interaction terms.
- Multivariable model: `glm`; report B, adjusted OR, 95% CI, p via `tbl_regression()` (exponentiate = FALSE and TRUE).
- Optional: check for confounders by change in coefficients > 20% when a variable is dropped.

## Stage 5: Assess model (A)
- Hosmer-Lemeshow GOF (`ResourceSelection::hoslem.test`, g = 10), plus overall LR chi-square and Nagelkerke/McFadden pseudo R2.
- Diagnostics per covariate pattern/observation: leverage (hat values), dbeta (Cook's-like, `cooks.distance`), dchisq (squared Pearson residual deltas). Plots vs predicted probability / index; list influential cases (leverage > 2(p+1)/n, dbeta > 1 or high, dchisq > ~4). Refit without influential cases as a sensitivity check.
- Discrimination: ROC curve and AUC with 95% CI (`pROC`).
- Classification: confusion matrix at 0.5 cut-off and at Youden-optimal cut-off; accuracy, sensitivity, specificity, PPV, NPV.

## Stage 6: Present (P)
- Table A: univariable (log odds B, crude OR, 95% CI, p).
- Table B: multivariable (B, adjusted OR, 95% CI, p), side-by-side with univariable via `tbl_merge()`.
- Table C: model fit summary (HL test, AUC, accuracy, etc.).
- Figures: ROC, diagnostic plots, EDA plots.
- Output: `output/tables/*.docx|html` (via `gt`/`gtsummary`) and a single Quarto report `report.qmd`.

## Deliverables / structure
```
Practical/
  AGENT.md
  implementation.md
  R/01_read_clean.R  02_explore.R  03_assumptions.R  04_models.R  05_diagnostics.R  06_tables.R
  data/clean/
  output/figures/  output/tables/  output/cleaning_log.md
  report.qmd
```

## Decisions confirmed by user
1. Data file: `stroke-fatality-cooked2.dta` (CSV ignored).
2. Outliers/impossible values: flag and list, ask user before any change. Missing data: complete-case analysis.
3. Selection: univariable p < 0.25 plus clinically important variables, then refine with LR tests; no interactions.
4. Output: Quarto HTML report (`report.qmd`) plus numbered R scripts.
5. Sex: 1 = Male, 2 = Female (reference = Male).
6. stroketype: keep 3 levels, Ischaemic (0) as reference.
7. Binary variables: 0 = reference; numeric ORs per 1-unit increase.

## Still open (minor; defaults will be used unless told otherwise)
- maritalstat coding (0/1 labels unknown): default 0 = reference, labelled "0"/"1" until confirmed. (Note: first rows are all 1.)
- If linearity in the logit fails: default = flag and ask, no automatic transformation.
- No new packages will be installed without asking (`car`, `naniar`, `performance` absent).
