# One check per course requirement. Each returns list(ok, detail).

links <- list(
  github_signup = "https://github.com/signup",
  github_education = "https://github.com/settings/education/benefits",
  ipums_signup = "https://uma.pop.umn.edu/usa/user/new",
  ipums_keys = "https://account.ipums.org/api_keys",
  kobo_signup = "https://kf.kobotoolbox.org/accounts/signup/"
)

kobo_server <- function() {
  s <- Sys.getenv("KOBO_SERVER")
  if (nzchar(s)) s else "https://kf.kobotoolbox.org"
}

check_tools <- function() {
  need <- c("git", "gh")
  missing <- need[!nzchar(vapply(need, find_tool, ""))]
  have_agents <- names(agents)[nzchar(vapply(names(agents), find_tool, ""))]
  if (!length(have_agents)) missing <- c(missing, "codex or claude")
  if (length(missing)) list(ok = FALSE, detail = paste("missing:", paste(missing, collapse = ", ")))
  else list(ok = TRUE, detail = paste(c(need, have_agents), collapse = ", "))
}

check_github <- function() {
  if (run_tool("gh", c("auth", "status"))$status != 0)
    return(list(ok = FALSE, detail = if (in_codespace()) "the codespace's GitHub sign-in did not reach R; reload the window" else "not signed in"))
  user <- run_tool("gh", c("api", "user", "--jq", ".login"))
  list(ok = user$status == 0, detail = trimws(user$out))
}

check_agent <- function() {
  id <- course_agent()
  if (is.na(id)) return(list(ok = FALSE, detail = if (in_codespace())
    "not signed in: sign in to Codex or Claude Code in the agent panel on the right" else "not signed in to Codex or Claude Code"))
  list(ok = TRUE, detail = paste(agents[[id]]$name, "signed in"))
}

check_kobo <- function() {
  tok <- Sys.getenv("KOBO_API_TOKEN")
  if (!nzchar(tok)) return(list(ok = FALSE, detail = "no key"))
  r <- http_status(paste0(kobo_server(), "/me/?format=json"), c(Authorization = paste("Token", tok)))
  if (r$status != 200) return(list(ok = FALSE, detail = paste("key refused, HTTP", r$status)))
  list(ok = TRUE, detail = jsonlite::fromJSON(r$body)$username)
}

check_ipums <- function() {
  key <- Sys.getenv("IPUMS_API_KEY")
  if (!nzchar(key)) return(list(ok = FALSE, detail = "no key"))
  r <- http_status("https://api.ipums.org/extracts?collection=usa&version=2&pageSize=1",
                   c(Authorization = key))
  if (r$status == 401 && grepl("not registered", r$body))
    return(list(ok = FALSE, detail = "key works, but this account is not registered for IPUMS USA yet"))
  if (r$status != 200) return(list(ok = FALSE, detail = paste("key refused, HTTP", r$status)))
  list(ok = TRUE, detail = "key works")
}

# The connector that lets the agent run code in the student's R session:
# in a codespace registered in each agent's settings (connect_agents), on the
# student's own computer passed on the command line by agent() (R/console.R).
has_connector <- function(id) {
  if (!file.exists(rscript_path()) || !requireNamespace("mcptools", quietly = TRUE)) return(FALSE)
  if (in_codespace()) {
    r <- run_tool(id, c("mcp", "get", "r-console"))
    return(r$status == 0)
  }
  if (id == "codex") return(TRUE)
  cfg <- tryCatch(jsonlite::fromJSON(claude_mcp_file(), simplifyVector = FALSE), error = function(e) NULL)
  identical(cfg$mcpServers$rstudio$command, rscript_path())
}

check_console_agent <- function() {
  id <- course_agent()
  if (is.na(id)) return(list(ok = FALSE, detail = "no agent signed in"))
  ok <- has_connector(id)
  list(ok = ok, detail = paste("R console connector", if (ok) "set up in" else "missing from", agents[[id]]$name))
}

check_folder <- function() {
  if (in_codespace()) return(list(ok = TRUE, detail = paste("codespace", Sys.getenv("CODESPACE_NAME"))))
  d <- course_dir()
  if (!dir.exists(d)) return(list(ok = FALSE, detail = paste("missing:", d)))
  if (synced_folder(d)) return(list(ok = FALSE, detail = paste("inside a cloud-synced folder:", d)))
  list(ok = TRUE, detail = d)
}

# Built when the package installs, before R/course.R defines check_course,
# hence the wrapper for it.
checks <- list(
  "Programs installed" = check_tools,
  "Course folder" = check_folder,
  "GitHub sign-in" = check_github,
  "AI agent sign-in" = check_agent,
  "KoboToolbox key" = check_kobo,
  "IPUMS key" = check_ipums,
  "Agent connected to R" = check_console_agent,
  "Course organization" = function() check_course(),
  "Course data" = function() check_data()
)

#' Print a pass or fail line for every course requirement.
#' @export
check <- function() {
  res <- lapply(checks, function(f) tryCatch(f(), error = function(e) list(ok = FALSE, detail = conditionMessage(e))))
  cat("\nPPOL 6818 setup check,", format(Sys.time(), "%Y-%m-%d %H:%M"), "\n")
  mark <- function(ok) if (is.na(ok)) "WAIT" else if (ok) "PASS" else "FAIL"
  for (n in names(res)) cat(sprintf("  %-34s %s  %s\n", n, mark(res[[n]]$ok), res[[n]]$detail))
  ok <- !any(vapply(res, function(r) isFALSE(r$ok), TRUE))
  cat(if (ok) "\nEverything passes. Submit this output on Canvas.\n"
      else "\nSomething failed. Click Course setup in the PPOL 6818 panel (or run ppol6818::setup() in the R console) to fix it.\n")
  invisible(res)
}
