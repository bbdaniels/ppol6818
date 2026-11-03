# One check per course requirement. Each returns list(ok, detail).

links <- list(
  github_signup = "https://github.com/signup",
  github_education = "https://github.com/settings/education/benefits",
  chatgpt = "https://chatgpt.com",
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
  need <- c("git", "gh", "codex", "opencode", "uvx")
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
  if (r$status != 200) return(list(ok = FALSE, detail = paste("key refused, HTTP", r$status)))
  list(ok = TRUE, detail = "key works")
}

# OpenCode reports live status from its background service, which needs a
# few seconds to reconnect after setup rewrites its configuration.
opencode_kobo_status <- function(tries = 5) {
  line <- ""
  for (i in seq_len(tries)) {
    out <- strsplit(run_tool("opencode", c("mcp", "list"))$out, "\n")[[1]]
    line <- trimws(grep("kobo", out, value = TRUE)[1] %||% "")
    if (grepl("connected", line) && !grepl("not connected|fail", line, ignore.case = TRUE)) return(list(ok = TRUE, line = line))
    Sys.sleep(3)
  }
  list(ok = FALSE, line = if (nzchar(line)) line else "kobo not listed")
}

check_kobo_agents <- function() {
  oc <- opencode_kobo_status()
  cx <- grepl("kobo", run_tool("codex", c("mcp", "list"))$out)
  list(ok = oc$ok && cx, detail = sprintf("Codex %s; OpenCode: %s",
                                          if (cx) "connected" else "not connected", oc$line))
}

checks <- list(
  "Programs installed" = check_tools,
  "GitHub sign-in" = check_github,
  "Codex sign-in" = check_codex,
  "KoboToolbox key" = check_kobo,
  "IPUMS key" = check_ipums,
  "Agents connected to KoboToolbox" = check_kobo_agents
)

#' Print a pass or fail line for every course requirement.
#' @export
check <- function() {
  res <- lapply(checks, function(f) tryCatch(f(), error = function(e) list(ok = FALSE, detail = conditionMessage(e))))
  cat("\nPPOL 6818 setup check,", format(Sys.time(), "%Y-%m-%d %H:%M"), "\n")
  for (n in names(res)) cat(sprintf("  %-34s %s  %s\n", n, if (res[[n]]$ok) "PASS" else "FAIL", res[[n]]$detail))
  ok <- all(vapply(res, `[[`, TRUE, "ok"))
  cat(if (ok) "\nEverything passes. Submit this output on Canvas.\n"
      else "\nSomething failed. Click Addins > Course setup to fix it.\n")
  invisible(res)
}
