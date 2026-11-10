# One check per course requirement. Each returns list(ok, detail).

links <- list(
  github_signup = "https://github.com/signup",
  github_education = "https://github.com/settings/education/benefits",
  chatgpt = "https://chatgpt.com",
  chatgpt_pricing = "https://chatgpt.com/pricing",
  codex_students = "https://chatgpt.com/codex/students",
  ipums_signup = "https://uma.pop.umn.edu/usa/user/new",
  ipums_keys = "https://account.ipums.org/api_keys",
  kobo_signup = "https://kf.kobotoolbox.org/accounts/signup/"
)

kobo_server <- function() {
  s <- Sys.getenv("KOBO_SERVER")
  if (nzchar(s)) s else "https://kf.kobotoolbox.org"
}

check_tools <- function() {
  need <- c("git", "gh", "codex")
  missing <- need[!nzchar(vapply(need, find_tool, ""))]
  if (length(missing)) list(ok = FALSE, detail = paste("missing:", paste(missing, collapse = ", ")))
  else list(ok = TRUE, detail = paste(need, collapse = ", "))
}

check_github <- function() {
  if (run_tool("gh", c("auth", "status"))$status != 0) return(list(ok = FALSE, detail = "not signed in"))
  user <- run_tool("gh", c("api", "user", "--jq", ".login"))
  list(ok = user$status == 0, detail = trimws(user$out))
}

check_codex <- function() {
  r <- run_tool("codex", c("login", "status"))
  list(ok = r$status == 0 && grepl("Logged in", r$out), detail = trimws(r$out))
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

# The connector that lets Codex run code in the RStudio session.
check_console_agent <- function() {
  ok <- grepl("rstudio", run_tool("codex", c("mcp", "list"))$out)
  list(ok = ok, detail = if (ok) "rstudio connector set up" else "rstudio connector missing")
}

check_folder <- function() {
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
  "Codex sign-in" = check_codex,
  "KoboToolbox key" = check_kobo,
  "IPUMS key" = check_ipums,
  "Codex connected to RStudio" = check_console_agent,
  "Course organization" = function() check_course()
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
      else "\nSomething failed. Click Addins > Course setup to fix it.\n")
  invisible(res)
}
