# E stage: missing, outliers, plots
suppressMessages({library(tidyverse); library(gtsummary)})
dat <- readRDS("data/clean/stroke_clean.rds")
nums <- dat |> select(where(is.numeric)) |> names()
cats <- dat |> select(where(is.factor)) |> names()
# missing
miss <- dat |> summarise(across(everything(), ~sum(is.na(.)))) |> pivot_longer(everything(), names_to="variable", values_to="n_missing")
write_csv(miss, "output/tables/missing.csv"); cat("Total missing:", sum(miss$n_missing), "\n")
# numeric plots
long <- dat |> select(all_of(nums)) |> pivot_longer(everything())
p1 <- ggplot(long, aes(value)) + geom_histogram(bins=20, fill="steelblue", colour="white") + facet_wrap(~name, scales="free") + theme_minimal()
ggsave("output/figures/hist_numeric.png", p1, width=10, height=8, dpi=150)
p2 <- ggplot(long, aes(y=value)) + geom_boxplot(fill="steelblue", alpha=.6) + facet_wrap(~name, scales="free") + theme_minimal() + theme(axis.text.x=element_blank())
ggsave("output/figures/box_numeric.png", p2, width=10, height=8, dpi=150)
longc <- dat |> select(all_of(cats)) |> mutate(across(everything(), as.character)) |> pivot_longer(everything())
p3 <- ggplot(longc, aes(value)) + geom_bar(fill="steelblue") + facet_wrap(~name, scales="free") + theme_minimal() + theme(axis.text.x=element_text(angle=30,hjust=1))
ggsave("output/figures/bar_categorical.png", p3, width=10, height=8, dpi=150)
# outliers: IQR rule + plausibility
iqr <- map_dfr(nums, \(v){x<-dat[[v]]; q<-quantile(x,c(.25,.75)); f<-1.5*diff(q)
  tibble(variable=v, lower=q[1]-f, upper=q[2]+f, n_out=sum(x<q[1]-f|x>q[2]+f), min=min(x), max=max(x))})
write_csv(iqr, "output/tables/outlier_iqr.csv"); print(iqr, n=20)
flag <- bind_rows(
  dat |> filter(gcs<3|gcs>15) |> transmute(rn, issue="GCS outside 3-15", value=gcs),
  dat |> filter(dbp>=sbp) |> transmute(rn, issue="DBP >= SBP", value=dbp),
  dat |> filter(na<120|na>160) |> transmute(rn, issue="Sodium <120 or >160", value=na),
  dat |> filter(hb<6|hb>19) |> transmute(rn, issue="Hb <6 or >19", value=hb),
  dat |> filter(plat<50|plat>600) |> transmute(rn, issue="Platelets <50 or >600", value=plat),
  dat |> filter(wbc>25) |> transmute(rn, issue="WBC >25", value=wbc),
  dat |> filter(potas<2.5|potas>6.5) |> transmute(rn, issue="Potassium <2.5 or >6.5", value=potas),
  dat |> filter(hr<40|hr>150) |> transmute(rn, issue="HR <40 or >150", value=hr),
  dat |> filter(cbs>25) |> transmute(rn, issue="Glucose (cbs) >25", value=cbs),
  dat |> filter(urea>30) |> transmute(rn, issue="Urea >30", value=urea),
  dat |> filter(age<18) |> transmute(rn, issue="Age <18", value=age))
write_csv(flag, "output/tables/flagged_values.csv"); print(flag, n=50)
print(table(dat$gcs))
# Table 1
t1 <- dat |> select(-rn) |> tbl_summary(by=outcome, statistic=list(all_continuous()~"{mean} ({sd})")) |> add_p() |> add_overall()
saveRDS(t1, "output/tables/table1.rds")
