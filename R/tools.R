# Finding and running the command-line tools the course uses.
# RStudio does not read the shell's startup files, so a tool installed into a
# user folder is often missing from PATH here; look in the install folders too.

# The user's home folder. On Windows, R's "~" is the Documents folder, which
# OneDrive often syncs; programs such as OpenCode use USERPROFILE instead.
home_dir <- function() {
  if (.Platform$OS.type == "windows" && nzchar(Sys.getenv("USERPROFILE")))
    normalizePath(Sys.getenv("USERPROFILE"), winslash = "/", mustWork = FALSE)
  else path.expand("~")
}

# A folder that iCloud, OneDrive, Dropbox or Google Drive syncs. Git
# repositories break there (files evicted, conflict copies inside .git), and
# IPUMS data in a repository's data folder would be uploaded to the cloud.
synced_folder <- function(d) {
  d <- normalizePath(d, winslash = "/", mustWork = FALSE)
  home <- home_dir()
  roots <- c(file.path(home, c("Documents", "Desktop")),
             file.path(home, "Library", c("Mobile Documents", "CloudStorage")),
             Sys.getenv(c("OneDrive", "OneDriveCommercial", "OneDriveConsumer")))
  roots <- normalizePath(roots[nzchar(roots)], winslash = "/", mustWork = FALSE)
  under <- function(r) tolower(d) == tolower(r) || startsWith(tolower(d), paste0(tolower(r), "/"))
  any(vapply(roots, under, TRUE)) ||
    grepl("onedrive|icloud|dropbox|google ?drive", d, ignore.case = TRUE)
}

tool_dirs <- function() {
  home <- home_dir()
  c(file.path(home, ".opencode", "bin"),
    file.path(home, ".local", "bin"),
    file.path(home, ".cargo", "bin"),
    "/opt/homebrew/bin", "/usr/local/bin",
    file.path(Sys.getenv("LOCALAPPDATA"), "Programs"),
    file.path(Sys.getenv("APPDATA"), "npm"),
    file.path(Sys.getenv("LOCALAPPDATA"), "Microsoft", "WinGet", "Links"),
    "C:/Program Files/GitHub CLI", "C:/Program Files/Git/cmd")
}

find_tool <- function(name) {
  hit <- Sys.which(name)
  if (nzchar(hit)) return(unname(hit))
  exe <- if (.Platform$OS.type == "windows") c(paste0(name, ".exe"), paste0(name, ".cmd")) else name
  for (d in tool_dirs()) for (e in exe) {
    p <- file.path(d, e)
    if (file.exists(p)) return(normalizePath(p))
  }
  ""
}

run_tool <- function(name, args = character(), timeout = 60) {
  path <- find_tool(name)
  if (!nzchar(path)) return(list(status = 127L, out = paste(name, "is not installed")))
  # system2 hands arguments to a shell unquoted; quote them so & ? and spaces survive.
  q <- if (.Platform$OS.type == "windows") shQuote(args, type = "cmd") else shQuote(args)
  out <- suppressWarnings(system2(path, q, stdout = TRUE, stderr = TRUE, timeout = timeout))
  status <- attr(out, "status")
  list(status = if (is.null(status)) 0L else status, out = paste(out, collapse = "\n"))
}

# Run a command in a visible RStudio Terminal, for steps the student must
# watch or answer (browser sign-ins).
in_terminal <- function(name, args = character()) {
  path <- find_tool(name)
  cmd <- paste(c(shQuote(path), args), collapse = " ")
  rstudioapi::terminalExecute(cmd, workingDir = getwd(), show = TRUE)
}

http_status <- function(url, headers = character()) {
  h <- curl::new_handle(timeout = 20)
  if (length(headers)) curl::handle_setheaders(h, .list = as.list(headers))
  r <- tryCatch(curl::curl_fetch_memory(url, handle = h), error = function(e) NULL)
  if (is.null(r)) return(list(status = 0L, body = ""))
  list(status = r$status_code, body = rawToChar(r$content))
}

# Keys live in the course folder's .Renviron: outside every repository and
# every synced folder. R reads only one .Renviron at startup (the working
# directory's, else ~/.Renviron), and each course repository is its own
# project, so every course .Rprofile calls load_keys() instead.
keys_file <- function() file.path(course_dir(), ".Renviron")
key_names <- c("KOBO_API_TOKEN", "IPUMS_API_KEY")

#' Load the course keys (KoboToolbox, IPUMS) into this R session.
#' @export
load_keys <- function() {
  f <- keys_file()
  if (file.exists(f)) readRenviron(f)
  invisible(f)
}

renviron_set <- function(key, value) {
  f <- keys_file()
  dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE)
  lines <- if (file.exists(f)) readLines(f, warn = FALSE) else character()
  lines <- lines[!startsWith(lines, paste0(key, "="))]
  writeLines(c(lines, paste0(key, "=", value)), f)
  Sys.chmod(f, "600")
  do.call(Sys.setenv, stats::setNames(list(value), key))
  invisible(TRUE)
}

# Earlier setups saved keys in ~/.Renviron (on Windows, Documents, often in
# OneDrive). Move them to the course folder and delete them there.
migrate_keys <- function() {
  old <- path.expand("~/.Renviron")
  if (!file.exists(old) || normalizePath(old) == normalizePath(keys_file(), mustWork = FALSE)) return(invisible())
  lines <- readLines(old, warn = FALSE)
  hit <- vapply(lines, function(l) any(startsWith(l, paste0(key_names, "="))), TRUE)
  if (!any(hit)) return(invisible())
  for (l in lines[hit]) {
    k <- sub("=.*", "", l)
    renviron_set(k, sub("^[^=]*=", "", l))
  }
  rest <- lines[!hit]
  if (length(rest) && any(nzchar(trimws(rest)))) writeLines(rest, old) else unlink(old)
  invisible()
}

state_file <- function(name) {
  d <- tools::R_user_dir("ppol6818", "cache")
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  file.path(d, name)
}
