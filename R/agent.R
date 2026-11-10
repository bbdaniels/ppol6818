# The course agent: Codex, in RStudio's Terminal.

#' Open Codex, the course AI agent, in RStudio's Terminal, in the current project.
#' @export
agent <- function() {
  rstudioapi::terminalExecute(shQuote(find_tool("codex")), workingDir = getwd(), show = TRUE)
  invisible()
}

# The working layout when RStudio opens a course project: the project's run.R
# in the editor above, Codex in the Terminal below. Only on a fresh RStudio
# session: after an R restart the earlier Terminal is still running Codex.
open_workspace <- function(newSession = TRUE) {
  if (!isTRUE(newSession) || !rstudioapi::isAvailable()) return(invisible())
  if (file.exists("run.R")) rstudioapi::navigateToFile("run.R")
  if (!nzchar(find_tool("codex")) || !isTRUE(check_codex()$ok)) return(invisible())
  agent()
}
