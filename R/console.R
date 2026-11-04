# The agent runs R in the student's RStudio session, through the Console,
# exactly as if the student pressed Run: the code is echoed in the Console,
# objects land in the Environment pane and plots in the Plots pane. The
# agent's own R process never runs course code.
#
# mcptools carries each tool call into the session, where it runs while R is
# idle at the prompt. Code sent to the Console runs only after the call
# returns, so running is two calls: run_in_console sends the code between two
# quiet markers, console_begin and console_done; console_output returns what
# it printed once console_done has run. An error drops the rest of the code's
# block, but the markers are separate Console inputs and still run.

console <- new.env(parent = emptyenv())

#' Make this RStudio session reachable by the course agent.
#'
#' Called from the course .Rprofile in interactive sessions.
#' @export
console_attach <- function() {
  if (interactive() && requireNamespace("mcptools", quietly = TRUE)) mcptools::mcp_session()
  invisible()
}

# The first quiet marker, run by the Console itself. Handlers that record
# messages, warnings and errors for console_output (which go to the Console's
# error stream, not into the capture) can only be registered at top level:
# RStudio reads .Rprofile, and runs tool calls, with handlers on the stack.
console_begin <- function() {
  if (!isTRUE(console$handlers)) {
    globalCallingHandlers(
      message = function(m) console_note("Message", conditionMessage(m)),
      warning = function(w) console_note("Warning", conditionMessage(w)),
      error = function(e) console_note("Error", conditionMessage(e)))
    console$handlers <- TRUE
  }
  sink(console$file, split = TRUE)
  console$sinks <- sink.number()
  console$running <- TRUE
  invisible()
}

console_note <- function(kind, text) {
  if (isTRUE(console$running)) console$notes <- c(console$notes, paste0(kind, ": ", sub("\n$", "", text)))
}

run_in_console <- function(code) {
  if (!rstudioapi::isAvailable())
    stop("Not connected to RStudio. Call list_r_sessions, then select_r_session with the RStudio session for this project, and try again.")
  if (isTRUE(console$active))
    return("Earlier code is still running in the Console. Call console_output until it finishes, then send this code again.")
  console$file <- tempfile(fileext = ".txt")
  console$notes <- character()
  console$active <- TRUE
  rstudioapi::sendToConsole("ppol6818:::console_begin()", execute = TRUE, echo = FALSE, focus = FALSE)
  rstudioapi::sendToConsole(code, execute = TRUE, echo = TRUE, focus = FALSE)
  rstudioapi::sendToConsole("ppol6818:::console_done()", execute = TRUE, echo = FALSE, focus = FALSE)
  "Sent to the RStudio Console. Call console_output to get what it printed."
}

# The quiet marker behind the agent's code: the code has finished.
console_done <- function() {
  while (sink.number() >= (console$sinks %||% 1L)) sink()
  console$running <- FALSE
  console$active <- FALSE
  invisible()
}

console_output <- function() {
  if (is.null(console$file)) return("Nothing has been sent to the Console.")
  if (isTRUE(console$active)) return("Still running in the Console. Call console_output again in a few seconds.")
  out <- readLines(console$file, warn = FALSE)
  unlink(console$file)
  console$file <- NULL
  if (length(out) > 200) out <- c(sprintf("(first %d lines omitted)", length(out) - 200), utils::tail(out, 200))
  out <- paste(out, collapse = "\n")
  if (!nzchar(trimws(out))) out <- "(no printed output)"
  if (length(console$notes)) out <- paste0(out, "\n\n", paste(console$notes, collapse = "\n"))
  out
}

console_tools <- function() {
  list(
    ellmer::tool(run_in_console, name = "run_in_console",
      description = paste(
        "Run R code in the student's RStudio session through the Console, as if the student pressed Run:",
        "the code is echoed in the Console, objects appear in the Environment pane and plots in the Plots pane.",
        "This is the only way to run R for this course. Then call console_output to read the result."),
      arguments = list(code = ellmer::type_string("The R code to run."))),
    ellmer::tool(console_output, name = "console_output",
      description = paste(
        "Return what the code last sent with run_in_console printed in the Console, with any messages, warnings and errors.",
        "If it says the code is still running, call it again."),
      arguments = list())
  )
}

#' The MCP server the course agents start: the Console tools, plus mcptools'
#' tools for choosing the RStudio session.
#' @export
console_server <- function() mcptools::mcp_server(tools = console_tools())

# Register the RStudio connector with both agents.
setup_console_agents <- function() {
  rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
  cmd <- c(rscript, "-e", "ppol6818::console_server()")
  run_tool("opencode", c("mcp", "add", "rstudio", "--global", "--", cmd))
  run_tool("codex", c("mcp", "remove", "rstudio"))
  run_tool("codex", c("mcp", "add", "rstudio", "--", cmd))
  invisible()
}
