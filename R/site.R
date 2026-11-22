# The pair minisite: a Quarto project at the repository root (the template's
# _quarto.yml) that renders the landing page, the deck and the two papers
# into docs/, the only folder GitHub Pages publishes. The project lists what
# it renders: each paper (midterm/midterm.qmd, final/final.qmd) renders to a
# PDF through the paper-typst format in _extensions/paper/, and the deck
# (deck.qmd) through deck-typst in _extensions/deck/; each PDF's page
# (midterm/index.qmd, final/index.qmd, deck/index.qmd) shows it. One quarto render
# builds it all. The course image and RStudio both include Quarto.

quarto_path <- function() {
  hit <- find_tool("quarto")
  if (nzchar(hit)) return(hit)
  env <- Sys.getenv(c("QUARTO_PATH", "RSTUDIO_QUARTO"))
  env <- env[nzchar(env) & file.exists(env)]
  if (length(env)) return(unname(env[1]))
  bundled <- c("/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto",
               file.path(Sys.getenv(c("ProgramFiles", "LOCALAPPDATA")), "RStudio", "resources", "app", "bin", "quarto", "bin", "quarto.exe"),
               "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe")
  bundled <- bundled[file.exists(bundled)]
  if (length(bundled)) normalizePath(bundled[1]) else ""
}

# The repository's address on GitHub, from its git remote, for the landing
# page's Repository link.
repo_url <- function() {
  r <- run_tool("git", c("remote", "get-url", "origin"))
  if (r$status != 0) return("")
  u <- sub("\\.git$", "", trimws(r$out))
  sub("^git@github.com:", "https://github.com/", u)
}

# Bring in the partner's pushed work before building, with the pull the
# codespace sync uses (pull_repo in course.R): local commits are replayed on
# top and uncommitted edits kept. A repository with no GitHub copy to pull
# from is built as it is.
pull_partner <- function(dir = ".") {
  if (git_run(dir, c("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"))$status != 0) {
    message("No GitHub copy to pull from: building the files as they are here.")
    return(invisible(FALSE))
  }
  r <- pull_repo(dir)
  if (r$stash)
    stop("Your partner's latest work is in, but it clashes with changes you had not committed",
         if (nzchar(r$clash)) paste0(", in ", r$clash), ". ",
         "Git kept your changes safe in its stash. Ask the agent to resolve the clash with you, then build again.", call. = FALSE)
  if (!r$ok) {
    if (grepl("conflict|could not apply", r$detail, ignore.case = TRUE))
      stop("Your partner's latest work clashes with your changes, so the build stopped. Nothing was changed. ",
           "Ask the agent to run `git pull --rebase` and resolve it with you, then build again.", call. = FALSE)
    stop("Could not bring in your partner's latest work, so the build stopped. Git said:\n", r$detail,
         "\nCheck your connection and build again.", call. = FALSE)
  }
  invisible(TRUE)
}

# The local files a page or paper shows: images, ![caption](path), and
# included files, {{< include path >}}, outside HTML comments and code
# blocks; as paths from the repository root.
exhibit_refs <- function(doc) {
  txt <- paste(readLines(doc, warn = FALSE), collapse = "\n")
  txt <- gsub("(?s)<!--.*?-->", "", txt, perl = TRUE)
  txt <- gsub("(?ms)^\\s*(```|~~~).*?^\\s*\\1", "", txt, perl = TRUE)
  grab <- function(pattern) {
    m <- regmatches(txt, gregexpr(pattern, txt, perl = TRUE))[[1]]
    sub(pattern, "\\1", m, perl = TRUE)
  }
  refs <- c(grab("!\\[(?:[^][]|\\[[^][]*\\])*\\]\\(\\s*<?([^)\\s>]+)"),
            grab("\\{\\{<\\s*include\\s+[\"']?([^\\s\"'>]+)"))
  refs <- refs[!grepl("^([A-Za-z][A-Za-z0-9+.-]*:|#|/)", refs)]
  d <- dirname(doc)
  unique(if (d == ".") refs else file.path(d, refs))
}

# Every exhibit a rendered page or paper shows must exist before the build
# (Quarto would leave a broken image on a page and stop on a missing
# include). Stops and names each missing file and the run file that makes it.
check_exhibits <- function(docs) {
  missing <- character()
  for (doc in docs) {
    refs <- exhibit_refs(doc)
    gone <- refs[!file.exists(refs)]
    if (!length(gone)) next
    run <- file.path(dirname(doc), "run.R")
    if (dirname(doc) == "." || !file.exists(run)) run <- "run.R"
    missing <- c(missing, paste0("  ", gone, ", in ", doc, ": run ", run))
  }
  if (length(missing))
    stop("The build stopped: these exhibits are missing.\n", paste(missing, collapse = "\n"),
         "\nRun the run file named beside each, or run.R, which runs them all. If your partner made the file, ",
         "ask them to commit and push it, then build again: the build pulls their work first.", call. = FALSE)
  invisible(TRUE)
}

# Each PDF's page names its PDF (pdf: in the page's front matter): the
# papers' pages and the deck's (deck/index.qmd shows ../deck.pdf). A source
# whose front matter lost its format line (paper-typst for a paper,
# deck-typst for the deck) renders to a web page instead, and its page would
# show nothing.
check_papers <- function(pages) {
  tidy <- function(p) sub("^\\./", "", gsub("[^/]+/\\.\\./", "", p))
  for (page in pages) {
    pdf <- grep("^pdf:", readLines(page, warn = FALSE), value = TRUE)
    if (!length(pdf)) next
    pdf <- tidy(file.path(dirname(page), gsub("^pdf:\\s*[\"']?|[\"']?\\s*$", "", pdf[1])))
    if (!file.exists(file.path("docs", pdf))) {
      src <- sub("\\.pdf$", ".qmd", pdf)
      fmt <- if (basename(src) == "deck.qmd") "deck-typst" else "paper-typst"
      stop("The build made no ", pdf, ". Keep the line `format: ", fmt, "` in the front matter of ",
           src, ", then build again.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

# The pages and papers the Quarto project renders: the list under project:
# render: in _quarto.yml, or, without one, every .qmd file whose name does
# not start with an underscore (Quarto's own rule). quarto inspect would say
# the same, but it fails outright on a missing include, before the check
# below can name the file.
project_inputs <- function() {
  y <- readLines("_quarto.yml", warn = FALSE)
  start <- grep("^\\s+render:\\s*$", y)
  files <- character()
  if (length(start)) {
    for (l in y[-seq_len(start[1])]) {
      if (grepl("^\\s*(#.*)?$", l)) next
      if (!grepl("^\\s+-\\s", l)) break
      files <- c(files, Sys.glob(gsub("^\\s+-\\s+[\"']?|[\"']?\\s*$", "", l)))
    }
  } else {
    files <- list.files(".", "\\.qmd$", recursive = TRUE)
    files <- files[!grepl("(^|/)[_.]", files) & !startsWith(files, "docs/")]
  }
  unique(files)
}

#' Build the minisite into docs/: the landing page, the deck, and the
#' registered report and final paper as PDFs, each shown on its own page.
#'
#' Click Build minisite in the PPOL 6818 section, or run
#' `ppol6818::build_site()` in the R console: in a codespace it builds your
#' pair's repository wherever the console is. It first pulls your
#' partner's pushed work (your own commits and uncommitted changes are
#' kept), then checks that every exhibit the pages and papers show is in
#' place, then renders. Nothing runs during the build: run.R makes the
#' exhibits. Afterwards, commit and push docs/.
#' @param path The repository's folder.
#' @param pull Bring in your partner's pushed work first.
#' @export
build_site <- function(path = ".", pull = TRUE) {
  if (!file.exists(file.path(path, "_quarto.yml")) && in_codespace() && nzchar(pair_repo()))
    path <- file.path(course_dir(), pair_repo())
  if (!file.exists(file.path(path, "_quarto.yml")))
    stop("No _quarto.yml here: open your pair's project repository first.", call. = FALSE)
  q <- quarto_path()
  if (!nzchar(q)) stop("Quarto was not found. The course codespace includes it; on your own computer, install it from https://quarto.org.", call. = FALSE)
  owd <- setwd(path); on.exit(setwd(owd))
  if (pull) pull_partner(".")
  inputs <- project_inputs()
  check_exhibits(inputs)
  old <- Sys.getenv("REPO_URL")
  Sys.setenv(REPO_URL = repo_url())
  on.exit(Sys.setenv(REPO_URL = old), add = TRUE)
  message("Building the minisite into docs/ ...")
  out <- suppressWarnings(system2(q, "render", stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(out, "status")) && attr(out, "status") != 0) {
    out <- gsub("\033\\[[0-9;]*m", "", out)
    first <- grep("^(ERROR|error)", out)
    said <- if (length(first)) out[first[1]:length(out)] else utils::tail(out, 20)
    stop("The minisite did not build. Quarto said:\n", paste(utils::head(said, 40), collapse = "\n"), call. = FALSE)
  }
  check_papers(inputs)
  file.create(file.path("docs", ".nojekyll"))  # GitHub Pages serves the files as they are
  site <- sub("^https://github.com/([^/]+)/(.+)$", "https://\\1.github.io/\\2/", repo_url())
  message("Built docs/. After you commit and push it, the minisite is at ", site,
          " (GitHub takes about a minute to publish).")
  invisible(site)
}
