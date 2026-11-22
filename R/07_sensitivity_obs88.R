# Sensitivity: final model with vs without obs 88 (B098506)
suppressMessages({library(tidyverse); library(pROC); library(ResourceSelection)})
d <- readRDS("data/clean/stroke_clean.rds"); d$dead <- as.integer(d$outcome=="Dead")
m <- readRDS("output/tables/final_model.rds"); d2 <- d[d$rn != "B098506",]; m2 <- update(m, data=d2)
row <- \(mod, dd, lab){ ci <- confint.default(mod); b <- coef(summary(mod)); r <- roc(dd$dead, fitted(mod), quiet=TRUE, direction="<")
  tibble(model=lab, n=nrow(dd), term=rownames(b), B=b[,1], SE=b[,2], OR=exp(b[,1]), lo=exp(ci[,1]), hi=exp(ci[,2]), p=b[,4], AUC=as.numeric(auc(r)),
         HL_p=hoslem.test(dd$dead, fitted(mod), g=10)$p.value)} |> filter(term!="(Intercept)")
res <- bind_rows(row(m,d,"All (n=226)"), row(m2,d2,"Without obs 88 (n=225)"))
write_csv(res,"output/tables/sensitivity_obs88.csv"); print(res |> mutate(across(where(is.numeric), ~round(.x,3))), width=200)
