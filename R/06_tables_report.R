# P stage: tables and self-contained HTML report (Quarto/pandoc unavailable, so built directly)
suppressMessages({library(tidyverse); library(gt); library(gtsummary); library(knitr)})
uv <- readRDS("output/tables/univariable.rds")$uv_tab; lrp <- readRDS("output/tables/univariable.rds")$lrp
mv <- read_csv("output/tables/multivariable_results.csv", show_col_types=FALSE)
fit <- read_csv("output/tables/fit_summary.csv", show_col_types=FALSE); cls <- read_csv("output/tables/classification.csv", show_col_types=FALSE)
sens <- read_csv("output/tables/sensitivity_gcs_models.csv", show_col_types=FALSE); sc <- read_csv("output/tables/sensitivity_gcs_cat_or.csv", show_col_types=FALSE)
vif <- read_csv("output/tables/vif.csv", show_col_types=FALSE); bt <- read_csv("output/tables/box_tidwell.csv", show_col_types=FALSE)
flag <- read_csv("output/tables/flagged_values.csv", show_col_types=FALSE)
fp <- \(p) ifelse(p<0.001,"<0.001",sprintf("%.3f",p))
mk <- \(d, title) d |> transmute(Variable=term, `Log odds (B)`=sprintf("%.3f",B), `SE`=sprintf("%.3f",SE), OR=sprintf("%.2f",OR), `95% CI`=sprintf("%.2f to %.2f",OR_lo,OR_hi), `p-value`=fp(p)) |>
  gt() |> tab_header(title=title) |> cols_align("center", -Variable)
uv2 <- uv |> mutate(term=str_replace(term, paste0("^", variable), paste0(variable, ": ")) |> str_replace(": $","") , p=p_wald)
mv2 <- mv |> mutate(term=recode(term, sexFemale="sex: Female", gcs="GCS (linear term)", `I(gcs^2)`="GCS squared"))
t_uv <- mk(uv2, "Table 2. Univariable (crude) logistic regression for in-hospital death") |> tab_source_note("Reference: male sex; No for binary factors; ischaemic stroke; hospital referral. Numeric variables per 1-unit increase. Wald 95% CI.")
t_mv <- mk(mv2, "Table 3. Multivariable logistic regression (final model with quadratic GCS, no interactions)") |> tab_source_note("Adjusted OR. Candidates entered p<0.25 univariable (LR test); GCS entered as linear + quadratic block; backward LR elimination at p<0.05 for the rest. Because of the quadratic term, the GCS effect is not a single OR (see predicted-probability plot). Wald 95% CI.")
t_fit <- fit |> mutate(value=ifelse(abs(value)<0.001 & value>0,sprintf("%.2e",value),sprintf("%.3f",value))) |> gt() |> tab_header(title="Table 4a. Model fit and discrimination")
t_cls <- cls |> mutate(across(c(accuracy,sensitivity,specificity,PPV,NPV), ~sprintf("%.1f%%",100*.x))) |> gt() |> tab_header(title="Table 4b. Classification (cut-off 0.5 and Youden-optimal)")
t_sens <- sens |> mutate(across(where(is.numeric), ~round(.x,3))) |> gt() |> tab_header(title="Table 5. Comparison of GCS specifications (sex + GCS): linear vs quadratic (final) vs categorised") |> tab_source_note("HL on few distinct covariate patterns; link_p = specification test.")
t_sc <- sc |> mutate(across(c(B,OR,lo,hi), ~round(.x,2)), p=fp(p)) |> gt() |> tab_header(title="Table 5b. Sex + GCS category (reference: GCS 13-15)")
so <- read_csv("output/tables/sensitivity_obs88.csv", show_col_types=FALSE)
t_so <- so |> mutate(term=recode(term, sexFemale="sex: Female", gcs="GCS (linear term)", `I(gcs^2)`="GCS squared")) |>
  transmute(Model=model, Term=term, B=sprintf("%.3f",B), OR=sprintf("%.2f",OR), `95% CI`=sprintf("%.2f to %.2f",lo,hi), `p-value`=fp(p), AUC=sprintf("%.3f",AUC), `HL p`=sprintf("%.3f",HL_p)) |>
  gt(groupname_col="Model") |> tab_header(title="Table 6. Sensitivity: final model with and without observation 88 (B098506)")
t_vif <- vif |> mutate(VIF=round(VIF,2)) |> gt() |> tab_header(title="VIF (final model)")
t_bt <- bt |> mutate(p_nonlinear=fp(p_nonlinear), flagged=ifelse(bt$p_nonlinear<0.05,"possible non-linearity","")) |> gt() |> tab_header(title="Box-Tidwell test for linearity in the logit (univariable)")
t1 <- readRDS("output/tables/table1.rds") |> as_gt() |> tab_header(title="Table 1. Characteristics by outcome at discharge")
t_flag <- flag |> gt() |> tab_header(title="Flagged values (retained; not altered)")
library(ggplot2)
dat0 <- readRDS("data/clean/stroke_clean.rds"); fm <- read_rds("output/tables/final_model.rds")
nd <- expand_grid(gcs=3:15, sex=factor(c("Male","Female"), levels=levels(dat0$sex))); nd$p <- predict(fm, nd, type="response")
ggsave("output/figures/pred_prob_gcs.png", ggplot(nd, aes(gcs, p, colour=sex)) + geom_line(linewidth=1) + geom_point() + theme_minimal() + labs(x="GCS", y="Predicted probability of death", colour="Sex"), width=6, height=4.5, dpi=150)
h <- \(x) as_raw_html(x, inline_css=TRUE)
img <- \(f, w="900") sprintf('<img src="%s" width="%s">', image_uri(f), w)
b <- \(r) fit$value[fit$metric==r]
html <- paste0('<!doctype html><html><head><meta charset="utf-8"><title>Stroke fatality logistic regression</title>
<style>body{font-family:-apple-system,Helvetica,Arial;max-width:980px;margin:2em auto;padding:0 1em;line-height:1.5}h2{border-bottom:1px solid #ccc;margin-top:2em}.note{background:#fff7e0;padding:.6em 1em;border-left:4px solid #e0a800}</style></head><body>
<h1>Predictors of in-hospital death after stroke</h1><p>n = 226; deaths = 62 (27.4%). Outcome: death at discharge (1) vs alive (0). Data: stroke-fatality-cooked2.dta.</p>
<h2>1. Read and explore</h2><p>No missing values. No duplicate IDs. No stroke type "Other" cases (3rd level dropped). Extreme but clinically possible values were flagged and retained (user to decide). Sodium 109 and 177 mmol/L (one patient with 177 also has WBC 27) are the most doubtful entries.</p>',
h(t1), h(t_flag), '<h3>Distributions</h3>', img("output/figures/hist_numeric.png"), img("output/figures/box_numeric.png"), img("output/figures/bar_categorical.png"),
'<h2>2. Assumptions</h2><div class="note"><b>Linearity in the logit:</b> GCS (p=0.015), SBP, DBP and random-glucose (cbs, p&lt;0.001) show possible non-linearity in the univariable Box-Tidwell test; GCS is also non-linear in the final model (p=0.004) and the link test is p=0.040. Per plan, no automatic transformation was applied; see sensitivity analysis. The final model therefore includes GCS as a linear + quadratic block. Events per variable with all 20 predictors = 3.1 (too low), 6.2 for the 10 candidates, about 21 for the final 3-term model.</div>',
h(t_bt), img("output/figures/linearity_logit.png", "800"),
'<h2>3. Univariable analysis</h2>', h(t_uv),
sprintf('<p>Variables with p&lt;0.25 (LR test): %s.</p>', paste(lrp$variable[lrp$candidate], collapse=", ")),
'<h2>4. Multivariable analysis</h2>', h(t_mv),
'<p>GCS entered as a linear plus quadratic block (chosen after non-linearity was found). After backward elimination only GCS and sex remained. Re-adding each removed candidate changed the retained coefficients by at most 12.6% (WBC), below the 20% confounding threshold, and the 8 removed terms jointly add nothing (LR p=0.92). Risk of death rises steeply as GCS falls from 15 towards about 5 and then flattens (curve peaks near GCS 4.6); female sex is associated with lower odds (adjusted OR 0.22, 95% CI 0.06-0.75, p=0.016). VIF is 1.07 for sex and about 3 for centred GCS terms (acceptable; raw polynomial terms are inevitably correlated).</p>', h(t_vif),
'<h2>5. Model assessment</h2>', h(t_fit), h(t_cls), img("output/figures/roc.png","500"), img("output/figures/pred_prob_gcs.png","600"), img("output/figures/diagnostics.png"),
'<p>Hosmer-Lemeshow: only 6 covariate-pattern groups could be formed because GCS is a coarse integer scale (df=4), p=0.596, no evidence of poor fit (low power). The link test is now p=0.746. No observation had dBeta &gt; 1 (max 0.18, obs 88). 8 had dChi-square &gt; 4; obs 88 (a death predicted at 0.6%) has dChi-square = 162 and is a clear outlier worth checking in the source record. Dropping the 8 poorly fitted cases changes coefficients markedly, so the precise estimates are sensitive to a few discordant patients.</p>',
'<h2>6. Sensitivity analyses</h2><h3>6a. Observation 88</h3><p>B098506 is a 94-year-old woman with GCS 15 who died (SBP 97, urea 30.7, diabetic); she is the only death among 134 patients with GCS 14-15 and is predicted at 0.6% risk. The record is clinically plausible and was retained in the main model. Excluding her strengthens the sex effect (adjusted OR 0.14) and steepens the GCS curve; conclusions are unchanged in direction, but the size of the sex effect depends partly on this one patient.</p>', h(t_so), '<h3>6b. GCS specification</h3>', h(t_sens), h(t_sc),
'<p>The quadratic specification lowers AIC (131 to 124) and removes the link-test problem; categorised GCS gives the same conclusion (severe/moderate vs mild GCS very strongly associated with death, female sex protective). The main conclusion (GCS dominant, female sex adjusted OR about 0.3) does not depend on the specification.</p></body></html>')
writeLines(html, "report.html")
writeLines(c("# Cleaning log","- Names cleaned with janitor::clean_names(); labelled Stata vars converted to factors.","- stroketype level 'Other' (code 2) had 0 observations; level dropped.","- maritalstat coding unknown; kept as 0/1.","- Missing values: none. Duplicate IDs: none.",
"- Extreme values flagged in output/tables/flagged_values.csv (19 flags). NOT altered; awaiting user decision (notably sodium 109 and 177, WBC 27 same patient B486178).","- Analysis: complete-case (all 226 rows)."), "output/cleaning_log.md")
cat("done\n")
