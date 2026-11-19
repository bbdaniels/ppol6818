# A week's lab answers: record them from run.R and check the public ones.
#
# Each lab with answers ships week-NN/answers-spec.csv (columns id,
# description, kind, target, tolerance) and week-NN/notes.md. run.R ends with
#   ppol6818::lab_answers(2, unins_ky_2013 = ky13, did_coef = coef(m)[["treat"]], ...)
# which writes week-NN/answers.csv and prints one line per answer: PASS or
# CHECK for a public answer (its target is in the starter), "recorded" for a
# private one (the course checks it), MISSING for an id not given. It then
# checks that notes.md has the student's own text under every heading.

lab_week_dir <- function(week, dir = NULL) {
  wk <- sprintf("week-%02d", as.integer(week))
  cands <- c(dir, file.path(getwd(), wk), file.path(codespace_repo()$dir, wk))
  for (d in cands) if (!is.null(d) && file.exists(file.path(d, "answers-spec.csv"))) return(normalizePath(d))
  stop("Cannot find ", wk, "/answers-spec.csv. Run run.R from your lab repository, where the R console starts.", call. = FALSE)
}

#' Record a lab's answers in week-NN/answers.csv and check the public ones.
#'
#' @param week The lab's week number.
#' @param ... One named value per answer id in week-NN/answers-spec.csv.
#' @param dir The week's folder, if not week-NN in the working directory.
#' @return The answers, invisibly, as a data frame.
#' @export
lab_answers <- function(week, ..., dir = NULL) {
  d <- lab_week_dir(week, dir)
  spec <- utils::read.csv(file.path(d, "answers-spec.csv"), stringsAsFactors = FALSE)
  given <- list(...)
  bad <- setdiff(names(given), spec$id)
  if (length(bad) || any(!nzchar(names(given) %||% ""))) {
    stop("Not an answer for week ", week, ": ", paste(bad, collapse = ", "),
         ". The answers are: ", paste(spec$id, collapse = ", "), call. = FALSE)
  }
  value <- vapply(spec$id, function(id) {
    v <- given[[id]]
    if (is.null(v) || length(v) == 0 || (length(v) == 1 && is.na(v))) return(NA_real_)
    if (length(v) != 1 || !is.numeric(v)) stop(id, " must be one number, not ", class(v)[1], " of length ", length(v), call. = FALSE)
    as.numeric(v)
  }, 0)
  out <- data.frame(id = spec$id, value = value, stringsAsFactors = FALSE)
  utils::write.csv(out, file.path(d, "answers.csv"), row.names = FALSE)

  cat(sprintf("\nWeek %d lab answers, written to %s\n", as.integer(week), file.path(basename(d), "answers.csv")))
  status <- character(nrow(spec))
  for (i in seq_len(nrow(spec))) {
    v <- value[i]
    if (is.na(v)) {
      status[i] <- "MISSING"; detail <- spec$description[i]
    } else if (spec$kind[i] == "public") {
      gap <- v - spec$target[i]
      status[i] <- if (abs(gap) <= spec$tolerance[i]) "PASS" else "CHECK"
      detail <- if (status[i] == "PASS") sprintf("%.2f (published %.1f, within %.1f)", v, spec$target[i], spec$tolerance[i])
                else sprintf("%.2f is %+.2f from the published %.1f (margin %.1f)", v, gap, spec$target[i], spec$tolerance[i])
    } else {
      status[i] <- "recorded"; detail <- sprintf("%.3f", v)
    }
    cat(sprintf("  %-18s %-8s  %s\n", spec$id[i], status[i], detail))
  }
  notes <- lab_notes(d)
  for (h in names(notes)) cat(sprintf("  %-18s %-8s  %s\n", "notes.md", if (notes[[h]]) "written" else "MISSING", h))

  n_miss <- sum(status == "MISSING") + sum(!unlist(notes))
  msg <- if (n_miss == 0 && !any(status == "CHECK")) "Every answer is recorded and every note written. Commit and push"
         else if (n_miss == 0) "Everything is recorded. A CHECK line is worth a second look with your agent before you commit and push"
         else "Not complete yet: fill in every MISSING line, run run.R again, then commit and push"
  cat(sprintf("\n%s week-%02d.\n", msg, as.integer(week)))
  invisible(out)
}

# For each heading of notes.md, whether the student wrote text of their own
# under it (anything other than the template's placeholder lines).
lab_notes <- function(d) {
  f <- file.path(d, "notes.md")
  if (!file.exists(f)) return(list(`notes.md is missing` = FALSE))
  x <- readLines(f, warn = FALSE)
  h <- grep("^## ", x)
  if (!length(h)) return(list())
  ends <- c(h[-1] - 1, length(x))
  res <- lapply(seq_along(h), function(i) {
    body <- if (ends[i] > h[i]) x[(h[i] + 1):ends[i]] else character()
    body <- trimws(body[!grepl("^\\s*(<!--.*-->)?\\s*$", body)])
    body <- body[!grepl("^_Write here", body)]
    length(body) > 0
  })
  stats::setNames(res, sub("^## ", "", x[h]))
}
