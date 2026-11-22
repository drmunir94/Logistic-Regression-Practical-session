# R + R stage: read and clean
suppressMessages({library(haven); library(tidyverse); library(janitor)})
raw <- read_dta("stroke-fatality-cooked2.dta") |> clean_names()
print(raw |> summarise(across(everything(), ~sum(is.na(.)))) |> pivot_longer(everything()) |> filter(value>0))
dat <- raw |>
  mutate(
    sex = factor(sex, levels = 1:2, labels = c("Male","Female")),
    outcome = factor(outcome, levels = 0:1, labels = c("Alive","Dead")),
    across(c(hypertension, diabetes, dyslipidaemia, malay),
           ~factor(as.numeric(.x), levels = 0:1, labels = c("No","Yes"))),
    maritalstat = factor(as.numeric(maritalstat), levels = 0:1, labels = c("0","1")), # coding unconfirmed
    referralcase = factor(as.numeric(referralcase), levels = 0:1, labels = c("Hospital","GP/home/missing")),
    stroketype = factor(as.numeric(stroketype), levels = 0:2, labels = c("Ischaemic","Haemorrhagic","Other")) |> droplevels() # no "Other" cases present
  )
saveRDS(dat, "data/clean/stroke_clean.rds")
glimpse(dat)
print(summary(dat |> select(where(is.numeric))))
for (v in c("sex","outcome","hypertension","diabetes","dyslipidaemia","malay","maritalstat","referralcase","stroketype")) print(table(dat[[v]], useNA="ifany"))
cat("dup ids:", sum(duplicated(dat$rn)), "\n")
