# The agent runs R in the student's RStudio session, through the Console, as
# if the student pressed Run: the code is echoed in the Console, objects land
# in the Environment pane and plots in the Plots pane. The agent's own R
# process never runs course code.
#
# mcptools carries each tool call into the session, where it runs while R is
# idle at the prompt. Code sent to the Console runs only after the call
# returns, so running is two calls. run_in_console stores the code and sends
# one line to the Console, ppol6818:::console_run(), which runs the code with
# its echo; console_run's exit handler marks the run finished however it
# ends (done, error, or the student pressing Stop). Nothing else is queued
# behind the code: RStudio may discard queued Console input after an error.

console <- new.env(parent = emptyenv())

#' Make this RStudio session reachable by the course agent.
#'
#' Called from the course .Rprofile in interactive sessions.
#' @export
console_attach <- function() {
  if (interactive() && requireNamespace("mcptools", quietly = TRUE)) mcptools::mcp_session()
  invisible()
}

run_in_console <- function(code) {
  if (!rstudioapi::isAvailable())
    stop("Not connected to RStudio. Call list_r_sessions, then select_r_session with the RStudio session for this project, and try again.")
  if (isTRUE(console$active))
    return("Earlier code is still running in the Console. Call console_output until it finishes, then send this code again.")
  parsed <- tryCatch(parse(text = code, keep.source = TRUE), error = function(e) e)
  if (inherits(parsed, "error"))
    return(paste("The code was not run: it does not parse.", conditionMessage(parsed)))
  console$code <- parsed
  console$text <- code
  console$file <- tempfile(fileext = ".txt")
  console$notes <- character()
  console$active <- TRUE
  console$sent <- Sys.time()
  rstudioapi::sendToConsole(console_call, execute = TRUE, echo = FALSE, focus = FALSE)
  "Sent to the RStudio Console. Call console_output to get what it printed."
}

# Runs the code the agent sent, at the Console; run_in_console sends this call.
console_run <- function() {
  if (!isTRUE(console$active) || is.null(console$code)) return(invisible())
  code <- console$code
  console$code <- NULL
  devices <- grDevices::dev.list()
  failed <- FALSE
  sink(console$file, split = TRUE)
  n <- sink.number()
  on.exit({
    while (sink.number() >= n) sink()
    # A file device (pdf, png) the code opened before failing would catch
    # every later plot, so none would reach the Plots pane.
    now <- grDevices::dev.list()
    left <- now[!now %in% devices]
    if (failed && length(left)) {
      for (d in left) grDevices::dev.off(d)
      console$notes <- c(console$notes, paste("Closed the graphics device the code left open:", paste(names(left), collapse = ", ")))
    }
    history_replace(console$text)
    console$active <- FALSE
  }, add = TRUE)
  note <- function(kind) function(cnd) {
    if (kind == "Error") failed <<- TRUE
    console$notes <- c(console$notes, paste0(kind, ": ", sub("\n$", "", conditionMessage(cnd))))
  }
  withCallingHandlers(
    source(exprs = code, local = globalenv(), echo = TRUE, print.eval = TRUE,
           spaced = FALSE, max.deparse.length = Inf, keep.source = TRUE,
           prompt.echo = "> ", continue.echo = "+ "),
    message = note("Message"), warning = note("Warning"), error = note("Error"))
  invisible()
}

# In the History pane, the agent's code takes the place of the one line that
# ran it, so History reads as if the student had pressed Run on that code.
console_call <- "ppol6818:::console_run()"
history_replace <- function(text) {
  h <- tempfile()
  on.exit(unlink(h))
  if (!isTRUE(tryCatch({ utils::savehistory(h); TRUE }, error = function(e) FALSE))) return(invisible())
  x <- readLines(h, warn = FALSE)
  i <- utils::tail(which(x == console_call), 1)
  if (length(i)) x <- x[-i]
  writeLines(c(x, strsplit(text, "\n", fixed = TRUE)[[1]]), h)
  utils::loadhistory(h)
  invisible()
}

console_output <- function() {
  if (is.null(console$file)) return("Nothing has been sent to the Console.")
  if (isTRUE(console$active)) {
    # This call runs only while R is idle at the prompt. So if console_run has
    # started (it took the code), it has ended; if it has not started after a
    # while, RStudio dropped it. Either way the run is over, never stuck.
    if (!is.null(console$code) && difftime(Sys.time(), console$sent, units = "secs") < 10)
      return("Still running in the Console. Call console_output again in a few seconds.")
    dropped <- !is.null(console$code)
    console$code <- NULL
    console$active <- FALSE
    if (dropped) {
      unlink(console$file)
      console$file <- NULL
      return("RStudio did not run the code (the Console was busy). Send it again with run_in_console.")
    }
  }
  out <- readLines(console$file, warn = FALSE)
  unlink(console$file)
  console$file <- NULL
  if (length(out) > 200) out <- c(sprintf("(first %d lines omitted)", length(out) - 200), utils::tail(out, 200))
  out <- paste(out, collapse = "\n")
  if (!nzchar(trimws(out))) out <- "(no printed output)"
  if (length(console$notes)) out <- paste0(out, "\n\n", paste(console$notes, collapse = "\n"))
  out
}

# mcptools sends each tool's function from the agent's server into the
# session. These wrappers only call the package installed in the session, so
# an updated package takes effect when R restarts, without restarting the agent.
console_tools <- function() {
  run <- function(code) ppol6818:::run_in_console(code)
  output <- function() ppol6818:::console_output()
  environment(run) <- environment(output) <- baseenv()
  list(
    ellmer::tool(run, name = "run_in_console",
      description = paste(
        "Run R code in the student's RStudio session through the Console, as if the student pressed Run:",
        "the code is echoed in the Console, objects appear in the Environment pane and plots in the Plots pane.",
        "This is the only way to run R for this course. Then call console_output to read the result.",
        "KoboToolbox is reached from R through the course package's kobo_* functions (forms, deploy, replace, submissions, export);",
        "run kobo_help() first to see them and their workflows."),
      arguments = list(code = ellmer::type_string("The R code to run."))),
    ellmer::tool(output, name = "console_output",
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
