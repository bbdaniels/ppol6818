# Run after an installer, from the course folder, by .github/workflows/installers.yml.
# Asserts what an installer must leave behind; sign-ins and keys are not
# available on a test machine, so their check lines are not asserted.
stopifnot(requireNamespace("ppol6818", quietly = TRUE))
home <- ppol6818:::home_dir()
want <- normalizePath(file.path(home, "Projects", "ppol-6818"), winslash = "/", mustWork = TRUE)
got <- normalizePath(ppol6818::course_dir(), winslash = "/", mustWork = TRUE)
cat("home:", home, "\ncourse folder:", got, "\n")
stopifnot(identical(tolower(got), tolower(want)))
stopifnot(file.exists(file.path(got, "ppol-6818.Rproj")), file.exists(file.path(got, ".Rprofile")))
stopifnot(!ppol6818:::synced_folder(got))
if (.Platform$OS.type == "windows") {
  stopifnot(!grepl("Documents", got, fixed = TRUE))
  stopifnot(startsWith(tolower(ppol6818:::opencode_global_config()),
                       tolower(file.path(home, ".config"))))
}
# Keys written by setup land in the course folder and load in a course repository.
ppol6818:::renviron_set("IPUMS_API_KEY", "test-key")
repo <- file.path(got, "zz-repo"); dir.create(repo)
file.copy(file.path(got, ".Rprofile"), file.path(repo, ".Rprofile"))
rscript <- file.path(R.home("bin"), "Rscript")
owd <- setwd(repo)
Sys.unsetenv("IPUMS_API_KEY")
out <- system2(rscript, c("-e", shQuote("cat(Sys.getenv('IPUMS_API_KEY'))")), stdout = TRUE)
setwd(owd)
cat("key in a course repository:", out, "\n")
stopifnot(identical(tail(out, 1), "test-key"))
res <- ppol6818::check()
stopifnot(isTRUE(res[["Programs installed"]]$ok), isTRUE(res[["Course folder"]]$ok))
cat("Installer test passed\n")
