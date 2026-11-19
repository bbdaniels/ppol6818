# The course's GitHub organization: accept its invitations and clone the
# student's course repositories into the course folder.

course_org <- "ppol-6818-2027"

#' The folder that holds the course project and every course repository:
#' ppol-6818 in the Projects folder of the home folder (made if missing; Mac
#' and Windows ignore case, so an existing "projects" folder is used), never
#' in a folder iCloud or OneDrive syncs. In a codespace, /workspaces, the
#' folder above the one repository the codespace holds.
#' @export
course_dir <- function() {
  d <- Sys.getenv("PPOL6818_DIR")
  if (nzchar(d)) d else if (in_codespace()) "/workspaces" else file.path(home_dir(), "Projects", "ppol-6818")
}

gh_json <- function(args) {
  r <- run_tool("gh", c("api", args))
  if (r$status != 0) return(NULL)
  tryCatch(jsonlite::fromJSON(r$out, simplifyVector = FALSE), error = function(e) NULL)
}

# Accept a pending invitation to the organization and to any course repository.
accept_invitations <- function() {
  accepted <- character()
  m <- gh_json(paste0("user/memberships/orgs/", course_org))
  if (!is.null(m) && identical(m$state, "pending")) {
    r <- run_tool("gh", c("api", "-X", "PATCH", paste0("user/memberships/orgs/", course_org), "-f", "state=active"))
    if (r$status == 0) accepted <- c(accepted, course_org)
  }
  for (inv in gh_json("user/repository_invitations") %||% list()) {
    full <- inv$repository$full_name %||% ""
    if (startsWith(full, paste0(course_org, "/"))) {
      r <- run_tool("gh", c("api", "-X", "PATCH", paste0("user/repository_invitations/", inv$id)))
      if (r$status == 0) accepted <- c(accepted, full)
    }
  }
  accepted
}

# Course repositories the student was added to directly (create_repos adds
# each student as a collaborator; organization-wide access does not count).
my_course_repos <- function() {
  repos <- gh_json(c("user/repos?per_page=100&affiliation=collaborator", "--paginate")) %||% list()
  names <- vapply(repos, function(r) if (identical(r$owner$login, course_org) && isTRUE(r$permissions$push) && !isTRUE(r$is_template)) r$full_name else NA_character_, "")
  sort(unique(names[!is.na(names)]))
}

clone_course_repos <- function() {
  dir.create(course_dir(), recursive = TRUE, showWarnings = FALSE)
  cloned <- character()
  for (full in my_course_repos()) {
    dest <- file.path(course_dir(), basename(full))
    if (dir.exists(dest)) next
    r <- run_tool("gh", c("repo", "clone", full, dest), timeout = 300)
    if (r$status == 0) cloned <- c(cloned, dest)
  }
  cloned
}

# The browser path: each student has one codespace, created on their lab
# repository (lab-<username>), and their pair's project repository is cloned
# beside it, at /workspaces/<project>. The lab repository's devcontainer asks
# for write access to the course's repositories (customizations.codespaces.
# repositories, ppol-6818-2027/*), which the student authorizes once when the
# codespace is created; GitHub's git credential then reaches the project
# repository. course/project in the lab repository names the project
# repository; the course writes it when pairs are formed.
git_run <- function(dir, args, timeout = 120) run_tool("git", c("-C", dir, args), timeout = timeout)

# Bring a repository up to date with GitHub: the student's own commits are
# replayed on top and uncommitted edits kept. Three outcomes:
# - ok: up to date, edits kept.
# - a clash between commits (stash = FALSE): the rebase is undone, nothing
#   changes.
# - a clash between the pulled work and uncommitted edits (stash = TRUE): git
#   pulls, then cannot put the edits back cleanly, so it keeps them in its
#   stash and marks the clash in the files (`clash` names them). Git reports
#   success here, so the stash list is compared before and after.
pull_repo <- function(dir) {
  stashes <- function() git_run(dir, c("stash", "list"))$out
  before <- stashes()
  r <- git_run(dir, c("pull", "--rebase", "--autostash", "--quiet"))
  if (r$status != 0) {
    git_run(dir, c("rebase", "--abort"))
    return(list(ok = FALSE, stash = FALSE, detail = r$out, clash = ""))
  }
  if (!identical(stashes(), before)) {
    clash <- git_run(dir, c("diff", "--name-only", "--diff-filter=U"))$out
    return(list(ok = FALSE, stash = TRUE, detail = r$out, clash = gsub("\n", ", ", trimws(clash))))
  }
  list(ok = TRUE, stash = FALSE, detail = "", clash = "")
}

# What to tell the student when pull_repo did not finish cleanly; `whose` is
# "the latest course files" or "your partner's latest work".
pull_problem <- function(r, name, dir, whose) {
  if (r$stash)
    return(paste0(name, ": ", whose, " is in, but it clashes with changes you had not committed",
                  if (nzchar(r$clash)) paste0(", in ", r$clash), ". Git kept your changes safe in its stash. ",
                  "Ask the agent to resolve the clash with you in ", dir, "."))
  paste0(name, ": could not bring in ", whose, ", because it clashes with your changes. ",
         "Nothing was changed. Ask the agent to run `git pull --rebase` in ", dir, " and resolve it with you.")
}

codespace_repo <- function() {
  repo <- Sys.getenv("GITHUB_REPOSITORY")
  if (!nzchar(repo)) return(list(name = "", dir = getwd()))
  list(name = basename(repo), dir = file.path(course_dir(), basename(repo)))
}

# The project repository named in the lab repository's course/project file.
pair_repo <- function(lab_dir = codespace_repo()$dir) {
  f <- file.path(lab_dir, "course", "project")
  if (!file.exists(f)) return("")
  trimws(readLines(f, n = 1, warn = FALSE))
}

# RStudio's Projects menu (top right) lists these, so the student switches
# between the lab and the pair project in one click.
remember_projects <- function(dirs) {
  rproj <- unlist(lapply(dirs, function(d) Sys.glob(file.path(d, "*.Rproj"))))
  if (!length(rproj)) return(invisible())
  f <- path.expand("~/.local/share/rstudio/monitored/lists/project_mru")
  dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE)
  old <- if (file.exists(f)) readLines(f, warn = FALSE) else character()
  writeLines(unique(c(rproj, old)), f)
  invisible()
}

sync_codespace <- function() {
  lab <- codespace_repo()
  out <- list(pulled = character(), cloned = character(), problems = character())
  if (dir.exists(file.path(lab$dir, ".git"))) {
    r <- pull_repo(lab$dir)
    if (r$ok) out$pulled <- lab$name
    else out$problems <- c(out$problems, pull_problem(r, lab$name, lab$dir, "the latest course files"))
  }
  proj <- pair_repo(lab$dir)
  if (nzchar(proj)) {
    dest <- file.path(course_dir(), proj)
    if (!dir.exists(dest)) {
      r <- run_tool("git", c("clone", "--quiet", paste0("https://github.com/", course_org, "/", proj, ".git"), dest), timeout = 300)
      if (r$status == 0) out$cloned <- proj
      else out$problems <- c(out$problems, paste0(
        "Your pair's repository, ", proj, ", could not be opened in this codespace. ",
        "This happens when the codespace was created without clicking Authorize and continue. ",
        "Commit and push your work, delete this codespace at https://github.com/codespaces, ",
        "then open your codespace again from Canvas and click Authorize and continue."))
    } else {
      r <- pull_repo(dest)
      if (r$ok) out$pulled <- c(out$pulled, proj)
      else out$problems <- c(out$problems, pull_problem(r, proj, dest, "your partner's latest work"))
    }
    remember_projects(c(lab$dir, dest))
  }
  where <- if (rstudioapi::isAvailable()) " (Projects menu, top right)" else " (in the file list on the left)"
  for (d in out$cloned) message("Your pair's repository is ready: ", file.path(course_dir(), d), where)
  if (length(out$problems)) tell("PPOL 6818", paste(out$problems, collapse = "\n\n"))
  invisible(out)
}

#' Accept course invitations and clone new course repositories; in a
#' codespace, bring the lab and project repositories up to date.
#' @export
sync_course <- function() {
  if (in_codespace()) return(sync_codespace())
  if (!check_github()$ok) return(invisible(list(accepted = character(), cloned = character())))
  acc <- accept_invitations()
  cl <- clone_course_repos()
  for (a in acc) message("Accepted the invitation to ", a)
  for (d in cl) message("Your course repository is ready: ", d)
  if (length(cl) && rstudioapi::isAvailable()) {
    open <- ask("Course repository", paste0("Open ", basename(cl[1]), " now?"))
    if (isTRUE(open)) rstudioapi::openProject(cl[1], newSession = FALSE)
  }
  invisible(list(accepted = acc, cloned = cl))
}

check_course <- function() {
  # The codespace's GitHub key reaches only its own repository, and opening a
  # course repository's codespace already took membership. Setup runs in a
  # codespace of the public template, which anyone can open.
  if (in_codespace()) {
    repo <- Sys.getenv("GITHUB_REPOSITORY")
    if (startsWith(repo, paste0(course_org, "/")) && !(basename(repo) %in% c("template", "lab-template", "pitch-template"))) {
      proj <- pair_repo()
      if (!nzchar(proj)) return(list(ok = TRUE, detail = paste(basename(repo), "(no pair repository yet)")))
      here <- dir.exists(file.path(course_dir(), proj, ".git"))
      return(list(ok = here, detail = if (here) paste(basename(repo), "and", proj)
                  else paste(proj, "not reachable: recreate the codespace and click Authorize and continue")))
    }
  }
  m <- gh_json(paste0("user/memberships/orgs/", course_org))
  if (is.null(m)) return(list(ok = NA, detail = "not invited yet (expected until you submit this output)"))
  if (!identical(m$state, "active")) return(list(ok = FALSE, detail = "invitation not accepted; click Addins > Course setup"))
  repos <- my_course_repos()
  list(ok = TRUE, detail = if (length(repos)) paste(basename(repos), collapse = ", ") else "member, no repositories yet")
}

# Run when the course project opens: full setup until it has passed once,
# then only the quick invitation and repository sync; then run.R opens in
# the editor and the course agent in the Terminal below it.
on_open <- function(newSession = TRUE) {
  done <- state_file("setup-passed")
  if (!file.exists(done)) {
    res <- setup()
    if (all(vapply(res, function(r) !isFALSE(r$ok), TRUE))) file.create(done)
  } else {
    sync_course()
  }
  open_workspace(newSession)
  invisible()
}

#' Create the course project folder (run by the installer); returns the
#' path of its .Rproj file.
#' @export
make_course_project <- function() {
  d <- course_dir()
  if (synced_folder(d))
    stop("The course folder ", d, " is inside a folder that iCloud, OneDrive or another cloud service syncs. ",
         "Course repositories must not be synced. Unset PPOL6818_DIR or set it to a folder outside it.", call. = FALSE)
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  src <- system.file("project", package = "ppol6818")
  file.copy(file.path(src, "ppol-6818.Rproj"), file.path(d, "ppol-6818.Rproj"), overwrite = TRUE)
  file.copy(file.path(src, "Rprofile"), file.path(d, ".Rprofile"), overwrite = TRUE)
  file.copy(file.path(src, "run.R"), file.path(d, "run.R"), overwrite = FALSE)
  file.path(d, "ppol-6818.Rproj")
}
