# Tests the steps build_site() takes before Quarto renders: reading the
# pages from _quarto.yml, finding the exhibits a page shows, stopping on a
# missing one, and pulling a partner's work without losing local work.
# Needs git; not Quarto. Run with Rscript tests/site.R once the package is
# installed. The full build (the PDFs and their pages) is tested against the
# pair template, not here.
stopifnot(requireNamespace("ppol6818", quietly = TRUE))
ns <- asNamespace("ppol6818")
stops_with <- function(expr, pattern) {
  msg <- tryCatch({ expr; "" }, error = conditionMessage)
  if (!grepl(pattern, msg, fixed = TRUE)) stop("Expected a stop with \"", pattern, "\", got: ", msg)
  invisible(msg)
}
git <- function(dir, ...) {
  r <- ns$git_run(dir, c(...))
  if (r$status != 0) stop("git ", paste(c(...), collapse = " "), " failed: ", r$out)
  invisible(r$out)
}
Sys.setenv(GIT_AUTHOR_NAME = "Test", GIT_AUTHOR_EMAIL = "test@example.com",
           GIT_COMMITTER_NAME = "Test", GIT_COMMITTER_EMAIL = "test@example.com")
tmp <- tempfile("site-test-"); dir.create(tmp)
owd <- setwd(tmp)

# A pair repository in miniature.
dir.create("midterm/exhibits", recursive = TRUE); dir.create("exhibits")
writeLines(c("project:", "  type: website", "  render:", "    - index.qmd", "    - midterm/*.qmd", "", "format: html"), "_quarto.yml")
writeLines(c("# Plan", "<!-- ![](exhibits/commented.png) -->", "![A figure](exhibits/week02.png)",
             "[a link](https://example.com/x.png) ![remote](https://example.com/y.png)"), "index.qmd")
writeLines(c("---", "title: x", "---", "![Caption with a [link](https://example.com).](exhibits/figure1.png){#fig-a}",
             "::: {#tbl-a}", "{{< include exhibits/table1.md >}}", "", "Caption.", ":::",
             "```", "![](exhibits/in-code.png)", "```", "<!--", "{{< include exhibits/in-comment.md >}}", "-->"), "midterm/midterm.qmd")
writeLines("# The run file", "midterm/run.R")
writeLines("x", "exhibits/week02.png")

inputs <- ns$project_inputs()
cat("pages:", inputs, "\n")
stopifnot(identical(sort(inputs), c("index.qmd", "midterm/midterm.qmd")))
stopifnot(identical(ns$exhibit_refs("index.qmd"), "exhibits/week02.png"))
stopifnot(identical(ns$exhibit_refs("midterm/midterm.qmd"), c("midterm/exhibits/figure1.png", "midterm/exhibits/table1.md")))
msg <- stops_with(ns$check_exhibits(inputs), "midterm/exhibits/figure1.png, in midterm/midterm.qmd: run midterm/run.R")
cat(msg, "\n")
stops_with(ns$check_exhibits(inputs), "midterm/exhibits/table1.md")
writeLines("x", "midterm/exhibits/figure1.png"); writeLines("| a |\n|---|\n| 1 |", "midterm/exhibits/table1.md")
stopifnot(isTRUE(ns$check_exhibits(inputs)))

# A paper page names a PDF the build did not make.
writeLines(c("---", "title: Registered report", "pdf: midterm.pdf", "---"), "midterm/index.qmd")
stops_with(ns$check_papers("midterm/index.qmd"), "format: paper-typst` in the front matter of midterm/midterm.qmd")
dir.create("deck"); writeLines(c("---", "title: Deck", "pdf: ../deck.pdf", "---"), "deck/index.qmd")
stops_with(ns$check_papers("deck/index.qmd"), "The build made no deck.pdf. Keep the line `format: deck-typst` in the front matter of deck.qmd")
dir.create("docs/midterm", recursive = TRUE); writeLines("x", "docs/midterm/midterm.pdf")
stopifnot(isTRUE(ns$check_papers("midterm/index.qmd")))
unlink("docs", recursive = TRUE)

# Pulling: a bare repository stands in for GitHub; A is the student, B the partner.
git(".", "init", "-q", "-b", "main"); git(".", "add", "-A"); git(".", "commit", "-qm", "seed")
git(tmp, "clone", "-q", "--bare", tmp, file.path(tmp, "origin.git"))
git(tmp, "clone", "-q", file.path(tmp, "origin.git"), file.path(tmp, "A"))
git(tmp, "clone", "-q", file.path(tmp, "origin.git"), file.path(tmp, "B"))
A <- file.path(tmp, "A"); B <- file.path(tmp, "B")

# No upstream: the build goes on with the files as they are.
git(tmp, "init", "-q", file.path(tmp, "solo"))
stopifnot(isFALSE(ns$pull_partner(file.path(tmp, "solo"))))

# The partner's commit comes in; the student's uncommitted edit stays.
cat("Partner's line.\n", file = file.path(B, "index.qmd"), append = TRUE)
git(B, "commit", "-qam", "Partner"); git(B, "push", "-q")
cat("Student's note.\n", file = file.path(A, "midterm/run.R"), append = TRUE)
stopifnot(isTRUE(ns$pull_partner(A)))
stopifnot(any(grepl("Partner's line.", readLines(file.path(A, "index.qmd")))))
stopifnot(any(grepl("Student's note.", readLines(file.path(A, "midterm/run.R")))))
git(A, "checkout", "-q", "midterm/run.R")

# A local commit that clashes: the build stops and nothing changes.
writeLines("partner", file.path(B, "exhibits/week02.png")); git(B, "commit", "-qam", "B"); git(B, "push", "-q")
writeLines("student", file.path(A, "exhibits/week02.png")); git(A, "commit", "-qam", "A")
head <- git(A, "rev-parse", "HEAD")
stops_with(ns$pull_partner(A), "clashes with your changes, so the build stopped. Nothing was changed.")
stopifnot(identical(git(A, "rev-parse", "HEAD"), head), !nzchar(git(A, "status", "--porcelain")))
git(A, "reset", "-q", "--hard", "origin/main")
git(A, "pull", "-q", "--rebase")

# An uncommitted edit that clashes: the build stops; the edit is in git's stash.
writeLines("partner 2", file.path(B, "exhibits/week02.png")); git(B, "commit", "-qam", "B2"); git(B, "push", "-q")
writeLines("student 2", file.path(A, "exhibits/week02.png"))
stops_with(ns$pull_partner(A), "Git kept your changes safe in its stash")
stopifnot(grepl("student 2", git(A, "stash", "show", "-p")))

# The codespace sync reads the same outcome from pull_repo: a stashed edit is
# a problem to tell the student, not a clean pull.
git(A, "reset", "-q", "--hard"); git(A, "stash", "drop", "-q")
writeLines("partner 3", file.path(B, "exhibits/week02.png")); git(B, "commit", "-qam", "B3"); git(B, "push", "-q")
writeLines("student 3", file.path(A, "exhibits/week02.png"))
r <- ns$pull_repo(A)
stopifnot(!r$ok, r$stash, r$clash == "exhibits/week02.png")
stopifnot(grepl("Git kept your changes safe in its stash", ns$pull_problem(r, "A", A, "your partner's latest work"), fixed = TRUE))

setwd(owd)
unlink(tmp, recursive = TRUE)
cat("Site tests passed\n")
