# Download a small IPUMS USA extract with your own key.
# Course setup saved the key as IPUMS_API_KEY in the course folder's
# .Renviron, which every course project loads at start; ipumsr then finds it.
# IPUMS data may not be shared, so the data file stays on
# your computer: the "data/" folder is in .gitignore, and this script is how
# anyone else gets the same data.

library(ipumsr)

extract <- define_extract_micro(
  collection = "usa",
  description = "PPOL 6818 example: 2022 ACS, age, sex and state",
  samples = "us2022a",
  variables = c("AGE", "SEX", "STATEFIP")
)

dir.create("data", showWarnings = FALSE)
submitted <- submit_extract(extract)
ready <- wait_for_extract(submitted)
files <- download_extract(ready, download_dir = "data", overwrite = TRUE)

acs <- read_ipums_micro(files)
nrow(acs)
