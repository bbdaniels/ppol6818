# The course agent. Each student uses the agent their
# own subscription runs: Codex with ChatGPT Plus, or Claude Code with Claude
# Pro. The installer installs both programs; setup asks which subscription the
# student has and signs that agent in.

agents <- list(
  codex = list(name = "Codex", account = "ChatGPT", plan = "ChatGPT Plus", login = "login"),
  claude = list(name = "Claude Code", account = "Claude", plan = "Claude Pro", login = c("auth", "login"))
)

signed_in <- function(id) {
  if (!nzchar(find_tool(id))) return(FALSE)
  if (id == "codex") {
    r <- run_tool("codex", c("login", "status"))
    r$status == 0 && grepl("Logged in", r$out)
  } else {
    r <- run_tool("claude", c("auth", "status"))
    grepl('"loggedIn": *true', r$out)
  }
}

# The agent this student uses: the one setup signed in, else whichever is
# signed in; NA when neither is.
course_agent <- function() {
  f <- state_file("agent")
  chosen <- if (file.exists(f)) readLines(f, warn = FALSE)[1] else character()
  for (id in unique(c(chosen[chosen %in% names(agents)], names(agents))))
    if (isTRUE(signed_in(id))) return(id)
  NA_character_
}

#' Open the course AI agent. In a codespace each agent has its own panel in
#' VS Code (Claude Code and Codex, on the right), so this says where; on the
#' student's own computer it runs the agent here, in this terminal, until the
#' student quits it.
#' @export
agent <- function() {
  if (in_codespace()) {
    message("The course agents are in the panel on the right of VS Code: Claude Code, and Codex in its own tab.")
    return(invisible())
  }
  id <- course_agent()
  if (is.na(id)) {
    setup_agent()
    id <- course_agent()
    if (is.na(id)) return(invisible())
  }
  system(paste(c(shQuote(find_tool(id)), connector_args(id)), collapse = " "))
  invisible()
}

# The working layout when the R console starts in a course repository: the
# newest run.R opens in the editor, through VS Code's command line. The R
# console is below it and the agents have their own panel, so nothing else
# opens.
open_workspace <- function(newSession = TRUE) {
  if (!isTRUE(newSession)) return(invisible())
  if (!nzchar(Sys.getenv("VSCODE_IPC_HOOK_CLI")) || !nzchar(Sys.which("code"))) return(invisible())
  # A lab repository has a folder a week (week-01, week-02, ...): open the
  # newest week's run.R.
  week <- utils::tail(sort(Sys.glob("week-[0-9][0-9]/run.R")), 1)
  file <- if (file.exists("run.R")) "run.R" else if (length(week)) week else character()
  if (length(file)) system2("code", c("--reuse-window", shQuote(normalizePath(file))), wait = FALSE)
  invisible()
}
