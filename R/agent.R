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

# The working layout when RStudio opens a course project: the project's run.R
# in the editor above, the agent in the Terminal below. Only on a fresh RStudio
# session: after an R restart the earlier Terminal is still running the agent.
open_workspace <- function(newSession = TRUE) {
  if (!isTRUE(newSession) || !rstudioapi::isAvailable()) return(invisible())
  # The course folder has its own run.R since this version; add it to older ones.
  if (!file.exists("run.R") && normalizePath(getwd(), mustWork = FALSE) == normalizePath(course_dir(), mustWork = FALSE))
    file.copy(system.file("project", "run.R", package = "ppol6818"), "run.R")
  if (file.exists("run.R")) rstudioapi::navigateToFile("run.R")
  if (is.na(course_agent())) return(invisible())
  agent()
}
