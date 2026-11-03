# The course agent: Codex by default, OpenCode with a free model when Codex
# is not signed in or stops with an error (for example, credits used up).

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
#' @param which "auto" (Codex, falling back to the free agent), "codex" or "free".
#' @export
agent <- function(which = c("auto", "codex", "free")) {
  which <- match.arg(which)
  codex <- find_tool("codex")
  opencode <- find_tool("opencode")
  if (which == "auto" && !check_codex()$ok) which <- "free"
  cmd <- switch(which,
    free = shQuote(opencode),
    codex = shQuote(codex),
    auto = paste0(shQuote(codex), ' || { echo; echo "Codex stopped. Switching to the free course agent."; ',
                  shQuote(opencode), "; }"))
  rstudioapi::terminalExecute(cmd, workingDir = getwd(), show = TRUE)
  invisible(which)
}

agent_free <- function() agent("free")
