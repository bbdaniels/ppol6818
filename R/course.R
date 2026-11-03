# The course's GitHub organization: accept its invitations and clone the
# student's course repositories into the course folder.

course_org <- "ppol-6818-2027"

#' The folder that holds the course project and every course repository:
#' ppol-6818 in the Projects folder of the home folder (made if missing; Mac
#' and Windows ignore case, so an existing "projects" folder is used), never
#' in a folder iCloud or OneDrive syncs.
#' @export
course_dir <- function() {
  d <- Sys.getenv("PPOL6818_DIR")
  if (nzchar(d)) d else file.path(home_dir(), "Projects", "ppol-6818")
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

#' Accept course invitations and clone new course repositories.
#' @export
sync_course <- function() {
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
  m <- gh_json(paste0("user/memberships/orgs/", course_org))
  if (is.null(m)) return(list(ok = NA, detail = "not invited yet (expected until you submit this output)"))
  if (!identical(m$state, "active")) return(list(ok = FALSE, detail = "invitation not accepted; click Addins > Course setup"))
  repos <- my_course_repos()
  list(ok = TRUE, detail = if (length(repos)) paste(basename(repos), collapse = ", ") else "member, no repositories yet")
}

# Run when the course project opens: full setup until it has passed once,
# then only the quick invitation and repository sync.
on_open <- function() {
  done <- state_file("setup-passed")
  if (!file.exists(done)) {
    res <- setup()
    if (all(vapply(res, function(r) !isFALSE(r$ok), TRUE))) file.create(done)
  } else {
    sync_course()
  }
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
  file.path(d, "ppol-6818.Rproj")
}
