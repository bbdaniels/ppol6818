# The Kobo forms of a shared account: names carry their maker, the lists
# put the caller's own first, and changing another's form stops. Run with
# Rscript tests/kobo.R from the package folder; no KoboToolbox calls are made.
library(ppol6818)
ns <- asNamespace("ppol6818")
Sys.setenv(GITHUB_USER = "ana", GITHUB_REPOSITORY = "ppol-6818-2027/project-ana-ben")
me <- ns$kobo_maker()
stopifnot(identical(me$tag, "(ana, project-ana-ben)"))
stopifnot(is.null(ns$form_maker("form")))
stopifnot(identical(ns$form_maker("form (ben, project-ana-ben)"), list(user = "ben", repo = "project-ana-ben")))
names <- c("form (ana, lab-ana)", "form (ben, project-ana-ben)", "form (cy, project-cy-di)", "Old form", NA)
stopifnot(identical(ns$is_mine(names, me), c(TRUE, TRUE, FALSE, FALSE, FALSE)))

# kobo_forms with a stubbed API: own forms first, mine = TRUE filters.
assets <- lapply(c("form (cy, project-cy-di)", "form (ana, lab-ana)", "Old form", "form (ben, project-ana-ben)"),
                 function(n) list(uid = paste0("u", nchar(n)), name = n, deployment_status = "deployed"))
unlockBinding("kobo_all", ns); assign("kobo_all", function(...) assets, ns)
f <- kobo_forms()
stopifnot(identical(f$name[1:2], c("form (ana, lab-ana)", "form (ben, project-ana-ben)")), identical(f$mine, c(TRUE, TRUE, FALSE, FALSE)))
stopifnot(nrow(kobo_forms(mine = TRUE)) == 2)

# Changing another's form stops before any change; others = TRUE goes on.
calls <- character()
unlockBinding("kobo_request", ns)
assign("kobo_request", function(path, method = "GET", ...) {
  calls <<- c(calls, paste(method, path))
  if (method == "GET") list(name = "form (cy, project-cy-di)") else NULL
}, ns)
e <- tryCatch(kobo_delete("x1"), error = conditionMessage)
stopifnot(grepl("others = TRUE", e), !any(grepl("^DELETE", calls)))
suppressMessages(kobo_delete("x1", others = TRUE))
stopifnot(any(calls == "DELETE /api/v2/assets/x1/"))
cat("kobo tests passed\n")
