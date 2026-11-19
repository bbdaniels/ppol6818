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
  if (!interactive()) return(invisible())
  if (in_codespace()) {
    one_console()
    start_watch()
  }
  if (requireNamespace("mcptools", quietly = TRUE)) mcptools::mcp_session()
  invisible()
}

# A codespace has one R console, the newest: each console, as it attaches,
# ends every other R console in a VS Code terminal. Each window reload opens
# a new console while the old one goes on running out of sight (VS Code's
# server keeps a closed window's terminals for hours), and with several
# consoles open the agent has to ask the student which one is theirs. A lock
# keeps two consoles attaching at once from ending each other; the later one
# stays. It ends them outright (SIGKILL): a console still running its
# .Rprofile does not stop on a polite signal. (Start times cannot decide it: the start script execs R, so a
# console started first may reach R last.)
one_console <- function() {
  lock <- "/tmp/ppol6818-console.lock"
  for (i in 1:50) {
    if (dir.create(lock, showWarnings = FALSE)) break
    age <- difftime(Sys.time(), file.mtime(lock), units = "secs")
    if (is.na(age) || age > 10) unlink(lock, recursive = TRUE) else Sys.sleep(0.2)
  }
  on.exit(unlink(lock, recursive = TRUE))
  for (pid in as.integer(grep("^[0-9]+$", dir("/proc"), value = TRUE))) {
    if (pid == Sys.getpid()) next
    p <- proc_info(pid)
    if (is.null(p) || !grepl("/exec/R ", p$cmd, fixed = TRUE)) next
    parent <- proc_info(p$ppid)
    if (!is.null(parent) && grepl("--type=ptyHost", parent$cmd, fixed = TRUE)) {
      ok <- tools::pskill(pid, tools::SIGKILL)
      cat(format(Sys.time(), "%F %T"), " console ", Sys.getpid(), " ended console ", pid,
          if (!ok) " (failed)", "\n", sep = "", file = "/tmp/ppol6818-console.log", append = TRUE)
    }
  }
  cat(format(Sys.time(), "%F %T"), " console ", Sys.getpid(), " attached\n", sep = "",
      file = "/tmp/ppol6818-console.log", append = TRUE)
}

# A process's command line and parent, from /proc; NULL once it has gone.
proc_info <- function(pid) {
  tryCatch({
    x <- readBin(sprintf("/proc/%d/cmdline", pid), "raw", 8192)
    x[x == as.raw(0)] <- as.raw(32)
    stat <- readLines(sprintf("/proc/%d/stat", pid), warn = FALSE)
    f <- strsplit(sub("^.*\\) ", "", stat), " ")[[1]]
    list(cmd = rawToChar(x), ppid = as.integer(f[2]))
  }, error = function(e) NULL, warning = function(w) NULL)
}

# The watch (inst/codespace/watch.sh) ends what a closed window left running.
# It runs from a copy named by its contents, since bash reads a script as it
# goes and the package is reinstalled at each codespace start.
start_watch <- function() {
  src <- system.file("codespace", "watch.sh", package = "ppol6818")
  if (!nzchar(src) || !nzchar(Sys.which("setsid"))) return(invisible())
  run <- sprintf("/tmp/ppol6818-watch-%s.sh", substr(unname(tools::md5sum(src)), 1, 8))
  if (!file.exists(run)) {
    file.copy(src, run)
    Sys.chmod(run, "755")
  }
  system2("setsid", c("-f", run), stdout = FALSE, stderr = FALSE, wait = FALSE)
  invisible()
}

run_in_console <- function(code) {
  # mcptools runs a tool in the agent's own server process when it reaches no
  # session (none open, or several it cannot choose between). Nothing may run
  # or print there: the server's output is the agent's message channel.
  if (!interactive()) return(no_console)
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
  if (rstudioapi::isAvailable()) {
    rstudioapi::sendToConsole(console_call, execute = TRUE, echo = FALSE, focus = FALSE)
    return("Sent to the RStudio Console. Call console_output to get what it printed.")
  }
  # R in a terminal (VS Code): this call already runs in the student's
  # session while it waits at the prompt, so the code runs here, echoed in
  # the terminal in place of the waiting prompt, which is drawn again after it.
  cat("\r")
  tryCatch(console_run(), error = function(e) cat("Error:", conditionMessage(e), "\n"))
  cat(getOption("prompt"))
  utils::flush.console()
  console_output()
}

no_console <- paste(
  "No R console is connected, so nothing was run.",
  "Call list_r_sessions: if it lists several, ask the student which R console they are using (or pick one if they do not mind), call select_r_session with it, then send the code again;",
  "if it lists none, ask the student to open the R console (the R terminal in VS Code) and try again.")

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
  if (!interactive()) return(no_console)
  # In a VS Code terminal, run_in_console already returned the output; asked
  # again, give the same output rather than "nothing sent".
  if (is.null(console$file)) return(console$last %||% "Nothing has been sent to the Console.")
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
  console$last <- out
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
        "Run R code in the student's own R session, as if the student ran it:",
        "the code and its output are echoed in the student's R console (VS Code's R terminal, or RStudio's Console),",
        "and the objects it makes stay in that session.",
        "This is the only way to run R for this course. It returns what the code printed, or, in RStudio, says it was sent, and then console_output reads the result.",
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

#' The MCP server the course agent starts: the Console tools, plus
#' mcptools' tools for choosing the RStudio session.
#' @export
console_server <- function() {
  find_consoles_by_socket()
  mcptools::mcp_server(tools = console_tools())
}

# mcptools (1.0.3) finds R sessions by trying slots 1, 2, 3 and so on, and
# stops at the first empty slot past slot 8. Each session takes the lowest
# free slot, so after window reloads the student's console can sit at slot 16
# while slots 9 to 15 have closed, and no agent finds it. This server's own
# copy of the search tries every slot that has a socket file, and otherwise
# does what mcptools does.
find_consoles_by_socket <- function() {
  ns <- asNamespace("mcptools")
  if (!is.function(ns$probe_sessions) || !is.function(ns$socket_dir_in_use)) return(invisible())
  probe <- function() {
    the <- get("the", envir = asNamespace("mcptools"))
    socket_dir <- get("socket_dir_in_use", envir = asNamespace("mcptools"))
    files <- list.files(socket_dir(), pattern = "^mcptools-socket[0-9]+$")
    slots <- sort(as.integer(sub("^mcptools-socket", "", files)))
    sock <- nanonext::socket("poly")
    on.exit(nanonext::reap(sock))
    cv <- nanonext::cv()
    monitor <- nanonext::monitor(sock, cv)
    live <- integer()
    for (i in slots) {
      rc <- nanonext::dial(sock, url = sprintf("%s%d", the$socket_url, i), autostart = NA, fail = "none")
      if (!nanonext::is_error_value(rc)) live <- c(live, i)
    }
    pipes <- nanonext::read_monitor(monitor)
    res <- lapply(pipes, function(x) nanonext::recv_aio(sock, mode = "raw", timeout = 5000L))
    lapply(pipes, function(x)
      nanonext::send_aio(sock, mac_seal(serialize(character(), NULL)), mode = "raw", pipe = x))
    results <- nanonext::collect_aio_(res)
    replies <- Filter(Negate(is.null), lapply(results, open_reply))
    list(live = live, sessions = lapply(replies, parse_session_reply))
  }
  environment(probe) <- ns
  utils::assignInNamespace("probe_sessions", probe, ns = "mcptools")
  invisible()
}

rscript_path <- function()
  file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")

# The agent gets the connector only when the course opens it from RStudio:
# agent() passes it on the command line (Codex: -c overrides; Claude Code:
# this file with --mcp-config). Registering it in the agent's own settings
# would make every session of that agent on the computer start an R process,
# course or not.
claude_mcp_file <- function() state_file("claude-mcp.json")

connector_args <- function(id) {
  if (id == "codex") {
    dq <- function(x) paste0('"', x, '"')
    return(c("-c", dq(paste0("mcp_servers.rstudio.command='", rscript_path(), "'")),
             "-c", dq("mcp_servers.rstudio.args=['-e','ppol6818::console_server()']")))
  }
  if (!file.exists(claude_mcp_file())) setup_console_agent()
  # Its tools only run code in the student's own Console; allowed up front,
  # since otherwise Claude Code asks before every call.
  c("--mcp-config", shQuote(claude_mcp_file()), "--allowedTools", "mcp__rstudio")
}

# Set up the RStudio connector for each agent installed, so either works.
setup_console_agent <- function() {
  # Earlier versions of this package registered it in each agent's own
  # settings; take that out.
  if (nzchar(find_tool("codex"))) run_tool("codex", c("mcp", "remove", "rstudio"))
  if (nzchar(find_tool("claude"))) {
    run_tool("claude", c("mcp", "remove", "-s", "user", "rstudio"))
    cfg <- list(mcpServers = list(rstudio = list(
      type = "stdio", command = rscript_path(), args = c("-e", "ppol6818::console_server()"))))
    jsonlite::write_json(cfg, claude_mcp_file(), auto_unbox = TRUE, pretty = TRUE)
  }
  invisible()
}

# In a codespace the student works in VS Code, where each agent runs in its
# own VS Code extension, started by VS Code and not by the course, so the
# connector is registered in each agent's own user settings. A codespace is
# the course's alone, so every agent session there may reach the R console.
# The course image's start script runs this at each codespace start.
#' Register the R console connector with Codex and Claude Code (codespaces).
#' @export
connect_agents <- function() {
  if (!in_codespace()) stop("connect_agents() is for course codespaces; on your own computer agent() connects the agent.")
  srv <- c(rscript_path(), "-e", "ppol6818::console_server()")
  done <- character()
  if (nzchar(find_tool("claude"))) {
    run_tool("claude", c("mcp", "remove", "-s", "user", "r-console"))
    r <- run_tool("claude", c("mcp", "add", "-s", "user", "r-console", "--", srv))
    if (r$status == 0) done <- c(done, "Claude Code")
    # Its tools only run code in the student's own R console; allowed up
    # front, since otherwise Claude Code asks before every call.
    f <- file.path(home_dir(), ".claude", "settings.json")
    cfg <- if (file.exists(f)) jsonlite::read_json(f) else list()
    allow <- unlist(cfg$permissions$allow)
    if (!"mcp__r-console" %in% allow) {
      cfg$permissions$allow <- as.list(c(allow, "mcp__r-console"))
      dir.create(dirname(f), showWarnings = FALSE, recursive = TRUE)
      jsonlite::write_json(cfg, f, auto_unbox = TRUE, pretty = TRUE)
    }
  }
  if (nzchar(find_tool("codex"))) {
    run_tool("codex", c("mcp", "remove", "r-console"))
    r <- run_tool("codex", c("mcp", "add", "r-console", "--", srv))
    if (r$status == 0) {
      done <- c(done, "Codex")
      # As for Claude Code, its tools are approved up front, since otherwise
      # Codex asks before every call (and refuses them in codex exec).
      f <- file.path(home_dir(), ".codex", "config.toml")
      x <- readLines(f, warn = FALSE)
      i <- which(x == "[mcp_servers.r-console]")
      if (length(i) == 1 && !any(grepl("^default_tools_approval_mode", x)))
        writeLines(append(x, 'default_tools_approval_mode = "approve"', after = i), f)
    }
  }
  message("R console connector registered for: ", if (length(done)) paste(done, collapse = ", ") else "no agent")
  invisible(done)
}
