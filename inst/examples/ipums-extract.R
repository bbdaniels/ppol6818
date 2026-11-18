# Get an IPUMS USA extract with ppol6818::ipums_get().
# In a codespace the course's IPUMS key is already there; on a computer of
# your own, course setup saved yours. Define the extract here, in code, so
# anyone who runs run.R gets the same data. Let IPUMS keep only the people you
# need (case selections), so the file stays small. The data go in data/ipums/,
# which git ignores: IPUMS microdata is never committed or published.

library(ppol6818)

ipums_get(
  name = "acs_kytn",
  samples = sprintf("us%da", 2011:2017),          # ACS one-year samples
  variables = list(
    "AGE", "PERWT", "PUMA", "HCOVANY",
    ipumsr::var_spec("STATEFIP", case_selections = c("21", "47"))  # Kentucky, Tennessee
  )
)

# Read only what you need; the filter runs before anything enters memory.
acs <- ipums_read("acs_kytn", columns = c("YEAR", "STATEFIP", "PUMA", "AGE", "PERWT", "HCOVANY"),
                  where = "AGE BETWEEN 19 AND 64")
ipums_labels("acs_kytn", "HCOVANY")
