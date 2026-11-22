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

# In a student's codespace, opened on the lab repository: a form deployed
# from the pair's folder is tagged with the pair repository, a form from the
# lab folder with the lab repository, and the partner's pair forms are theirs.
ws <- file.path(tempfile("ws"))
for (r in c("lab-ana", "project-ana-ben")) dir.create(file.path(ws, r, ".git"), recursive = TRUE)
dir.create(file.path(ws, "lab-ana", "course")); writeLines("project-ana-ben", file.path(ws, "lab-ana", "course", "project"))
dir.create(file.path(ws, "project-ana-ben", "survey")); invisible(file.create(file.path(ws, "project-ana-ben", "survey", "form.xlsx")))
old <- Sys.getenv(c("GITHUB_REPOSITORY", "PPOL6818_DIR"))
Sys.setenv(GITHUB_REPOSITORY = "ppol-6818-2027/lab-ana", PPOL6818_DIR = ws)
stopifnot(identical(ns$kobo_maker(file.path(ws, "project-ana-ben", "survey", "form.xlsx"))$tag, "(ana, project-ana-ben)"))
stopifnot(identical(ns$kobo_maker(file.path(ws, "lab-ana", "week-07", "form.xlsx"))$tag, "(ana, lab-ana)"))
stopifnot(identical(ns$kobo_maker(file.path(tempdir(), "nowhere", "form.xlsx"))$tag, "(ana, lab-ana)"))
stopifnot(identical(ns$is_mine(c("f (ben, project-ana-ben)", "f (ben, lab-ben)", "f (cy, project-cy-di)")), c(TRUE, FALSE, FALSE)))
do.call(Sys.setenv, as.list(old))
unlink(ws, recursive = TRUE)

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
