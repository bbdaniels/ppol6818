# The course agent, in RStudio's Terminal. Each student uses the agent their
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

#' Open the course AI agent (Codex or Claude Code, whichever the student
#' signed in to) in RStudio's Terminal, in the current project.
#' @export
agent <- function() {
  id <- course_agent()
  if (is.na(id)) {
    setup_agent()
    id <- course_agent()
    if (is.na(id)) return(invisible())
  }
  rstudioapi::terminalExecute(paste(c(shQuote(find_tool(id)), connector_args(id)), collapse = " "),
                              workingDir = getwd(), show = TRUE)
  invisible()
}

# The working layout when a course project opens: the newest run.R in the
# editor and the agent beside it. In RStudio (the student's own computer) the
# agent runs in the Terminal below; only on a fresh RStudio session, since
# after an R restart the earlier Terminal is still running the agent. In VS
# Code (a codespace) R runs in the terminal below the editor and the agent has
# its own panel, so only run.R is opened, through VS Code's command line.
open_workspace <- function(newSession = TRUE) {
  if (!isTRUE(newSession)) return(invisible())
  rstudio <- rstudioapi::isAvailable()
  vscode <- nzchar(Sys.getenv("VSCODE_IPC_HOOK_CLI")) && nzchar(Sys.which("code"))
  if (!rstudio && !vscode) return(invisible())
  # The course folder has its own run.R since this version; add it to older ones.
  if (!file.exists("run.R") && normalizePath(getwd(), mustWork = FALSE) == normalizePath(course_dir(), mustWork = FALSE))
    file.copy(system.file("project", "run.R", package = "ppol6818"), "run.R")
  # A lab repository has a folder a week (week-01, week-02, ...): open the
  # newest week's run.R.
  week <- utils::tail(sort(Sys.glob("week-[0-9][0-9]/run.R")), 1)
  file <- if (file.exists("run.R")) "run.R" else if (length(week)) week else character()
  if (vscode) {
    if (length(file)) system2("code", c("--reuse-window", shQuote(normalizePath(file))), wait = FALSE)
    return(invisible())
  }
  if (length(file)) rstudioapi::navigateToFile(file)
  if (is.na(course_agent())) return(invisible())
  agent()
}
