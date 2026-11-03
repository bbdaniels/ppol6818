# The course agent. OpenCode on a free GLM model is the default; Codex is
# installed as the alternative. To switch the course to Codex, set
# default_agent to "codex": setup then requires the Codex sign-in and
# Addins > Course agent opens Codex.

default_agent <- "opencode"
free_model <- "opencode/glm-5.3-flash-free"

opencode_global_config <- function() {
  file.path(Sys.getenv("XDG_CONFIG_HOME", path.expand("~/.config")), "opencode", "opencode.json")
}

opencode_set_kobo <- function(uvx, tok) {
  run_tool("opencode", c("mcp", "add", "kobo", "--global",
                         "--env", paste0("KOBO_API_TOKEN=", tok),
                         "--env", paste0("KOBO_SERVER=", kobo_server()),
                         "--", uvx, "kobo-mcp"))
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

#' Open the other agent (Codex when the default is OpenCode, and the reverse).
#' @export
agent_other <- function() agent(setdiff(c("opencode", "codex"), default_agent))
