# A stage: assumptions + univariable logistic regression
suppressMessages({library(tidyverse); library(gtsummary); library(broom)})
dat <- readRDS("data/clean/stroke_clean.rds") |> select(-rn)
dat$dead <- as.integer(dat$outcome == "Dead")
nums <- dat |> select(where(is.numeric), -dead) |> names()
preds <- setdiff(names(dat), c("outcome","dead"))
cat("Events:", sum(dat$dead), " Non-events:", sum(1-dat$dead), "\n")
cat("EPV with all 20 predictors (df=", length(nums)+sum(map_int(dat |> select(where(is.factor), -outcome), ~nlevels(.x)-1)), "):",
    round(sum(dat$dead)/(length(nums)+sum(map_int(dat |> select(where(is.factor), -outcome), ~nlevels(.x)-1))),1), "\n")
# Linearity in logit: Box-Tidwell
bt <- map_dfr(nums, \(v){
  d <- dat; d$x <- d[[v]]; d$xlx <- d$x*log(d$x)
  m <- glm(dead ~ x + xlx, data=d, family=binomial)
  tibble(variable=v, p_nonlinear=coef(summary(m))["xlx",4])})
write_csv(bt, "output/tables/box_tidwell.csv"); print(bt)
# Binned logit plots (quintile means)
lp <- dat |> select(dead, all_of(nums)) |> pivot_longer(-dead) |> group_by(name) |>
  mutate(bin=ntile(value,5)) |> group_by(name,bin) |> summarise(x=mean(value), p=mean(dead), .groups="drop") |>
  mutate(p=pmin(pmax(p,0.01),0.99), logit=log(p/(1-p)))
g <- ggplot(lp, aes(x, logit)) + geom_point() + geom_smooth(method="lm", se=FALSE, colour="red", linewidth=.5) + facet_wrap(~name, scales="free_x") + theme_minimal() + labs(y="Empirical logit (quintile bins)")
ggsave("output/figures/linearity_logit.png", g, width=10, height=8, dpi=150)
# Univariable (manual tables with broom: broom.helpers is not installed, so gtsummary regression tables are avoided)
uv_data <- dat |> select(dead, all_of(preds))
uv_tab <- map_dfr(preds, \(v){
  m <- glm(reformulate(v,"dead"), data=uv_data, family=binomial)
  ci <- suppressMessages(confint.default(m))
  tidy(m) |> filter(term != "(Intercept)") |>
    transmute(variable=v, term, B=estimate, SE=std.error, OR=exp(estimate),
              OR_lo=exp(ci[term,1]), OR_hi=exp(ci[term,2]), p_wald=p.value)
})
lrp <- map_dfr(preds, \(v){ m0 <- glm(dead~1,data=uv_data,family=binomial); m1 <- glm(reformulate(v,"dead"),data=uv_data,family=binomial)
  tibble(variable=v, p_lr=anova(m0,m1,test="LRT")$`Pr(>Chi)`[2])})
lrp$candidate <- lrp$p_lr < 0.25
write_csv(uv_tab, "output/tables/univariable_results.csv")
write_csv(lrp, "output/tables/univariable_lr_p.csv"); print(lrp |> arrange(p_lr), n=30)
print(uv_tab |> mutate(across(where(is.numeric), ~round(.x,3))), n=40)
saveRDS(list(uv_tab=uv_tab, lrp=lrp), "output/tables/univariable.rds")
