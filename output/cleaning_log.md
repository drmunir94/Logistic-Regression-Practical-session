# Cleaning log
- Names cleaned with janitor::clean_names(); labelled Stata vars converted to factors.
- stroketype level 'Other' (code 2) had 0 observations; level dropped.
- maritalstat coding unknown; kept as 0/1.
- Missing values: none. Duplicate IDs: none.
- Extreme values flagged in output/tables/flagged_values.csv (19 flags). NOT altered; awaiting user decision (notably sodium 109 and 177, WBC 27 same patient B486178).
- Analysis: complete-case (all 226 rows).
