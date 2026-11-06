# The course agent. OpenCode on a free GLM model is the default; Codex is
# installed as the alternative. To switch the course to Codex, set
# default_agent to "codex": setup then requires the Codex sign-in and
# Addins > Course agent opens Codex.

default_agent <- "opencode"
free_model <- "opencode/glm-5.3-flash-free"

opencode_global_config <- function() {
  file.path(Sys.getenv("XDG_CONFIG_HOME", file.path(home_dir(), ".config")), "opencode", "opencode.json")
}

# Earlier course setups registered the kobo-mcp connector with both agents,
# with the KoboToolbox key in their configuration files. The kobo_*
# functions replace it; remove the entry and the key it holds.
remove_kobo_connector <- function() {
  run_tool("codex", c("mcp", "remove", "kobo"))
  f <- opencode_global_config()
  if (!file.exists(f)) return(invisible())
  cfg <- jsonlite::read_json(f)
  if (is.null(cfg$mcp$servers$kobo) && is.null(cfg$mcp$kobo)) return(invisible())
  cfg$mcp$servers$kobo <- NULL
  cfg$mcp$kobo <- NULL
  jsonlite::write_json(cfg, f, auto_unbox = TRUE, pretty = TRUE)
}

# The free model is the default for OpenCode everywhere, not per project.
opencode_set_model <- function() {
  f <- opencode_global_config()
  cfg <- if (file.exists(f)) jsonlite::read_json(f) else list("$schema" = "https://opencode.ai/config.json")
  if (identical(cfg$model, free_model)) return(invisible())
  cfg$model <- free_model
  dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(cfg, f, auto_unbox = TRUE, pretty = TRUE)
}

#' Open the course AI agent in RStudio's Terminal, in the current project.
#' @param which "opencode" or "codex"; the course default when omitted.
#' @export
agent <- function(which = default_agent) {
  which <- match.arg(which, c("opencode", "codex"))
  rstudioapi::terminalExecute(shQuote(find_tool(which)), workingDir = getwd(), show = TRUE)
  invisible(which)
}

# The working layout when RStudio opens a course project: the project's run.R
# in the editor above, the course agent in the Terminal below. Only on a
# fresh RStudio session: after an R restart the earlier Terminal is still
# running the agent.
open_workspace <- function(newSession = TRUE) {
  if (!isTRUE(newSession) || !rstudioapi::isAvailable()) return(invisible())
  if (file.exists("run.R")) rstudioapi::navigateToFile("run.R")
  if (!nzchar(find_tool(default_agent))) return(invisible())
  if (default_agent == "codex" && !isTRUE(check_codex()$ok)) return(invisible())
  agent()
}

#' Open the other agent (Codex when the default is OpenCode, and the reverse).
#' @export
agent_other <- function() agent(setdiff(c("opencode", "codex"), default_agent))
