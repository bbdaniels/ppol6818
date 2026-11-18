# Course setup: each step checks first and acts only when the check fails.
# Web sign-ins cannot be seen from R, so a missing account is detected by its
# key or command-line sign-in failing; the student is then asked whether they
# have an account, and sent to the sign-up page if not.

ask <- function(title, message, yes = "Yes", no = "No") {
  if (rstudioapi::isAvailable()) rstudioapi::showQuestion(title, message, yes, no)
  else utils::askYesNo(message)
}

tell <- function(title, message) {
  if (rstudioapi::isAvailable()) rstudioapi::showDialog(title, message) else message(message)
}

secret <- function(prompt) {
  v <- if (rstudioapi::isAvailable()) rstudioapi::askForSecret("ppol6818", prompt, prompt)
       else readline(paste0(prompt, ": "))
  if (is.null(v)) "" else trimws(v)
}

# Wait for a sign-in the student completes in the browser or the Terminal.
wait_for <- function(check_fn, what, minutes = 10) {
  message("Waiting for ", what, " (finish it in the browser, then come back) ...")
  end <- Sys.time() + minutes * 60
  while (Sys.time() < end) {
    if (isTRUE(check_fn()$ok)) return(TRUE)
    Sys.sleep(3)
  }
  FALSE
}

account_first <- function(service, signup, extra = NULL) {
  if (!ask(service, paste0("Do you already have a ", service, " account?"))) {
    utils::browseURL(signup)
    tell(service, paste0("A sign-up page for ", service, " is open in your browser. ",
                         "Create the account with your personal email, so you keep it after Georgetown. ",
                         "Confirm your email, then click OK here."))
    if (!is.null(extra)) extra()
  }
}

setup_github <- function() {
  if (check_github()$ok || in_codespace()) return(invisible())
  account_first("GitHub", links$github_signup, function() {
    utils::browseURL(links$github_education)
    tell("GitHub", paste("The GitHub Education page is open. Add your Georgetown email to your GitHub account",
                         "as a second address (Settings > Emails), then apply with it",
                         "(approval can take a few days; you can keep going). Click OK when submitted."))
  })
  in_terminal("gh", c("auth", "login", "--web", "--hostname", "github.com", "--git-protocol", "https"))
  tell("GitHub", "The Terminal shows a one-time code. Press Enter there, paste the code in the browser, and approve.")
  wait_for(check_github, "GitHub sign-in")
  run_tool("gh", c("auth", "setup-git"))
}

# The course requires ChatGPT Plus or Claude Pro before the first class
# (syllabus). Ask which one the student has, then sign that agent in: its
# sign-in runs in the Terminal and opens the browser.
setup_agent <- function() {
  if (!is.na(course_agent())) return(invisible())
  installed <- names(agents)[nzchar(vapply(names(agents), find_tool, ""))]
  if (!length(installed)) return(invisible())
  id <- if (length(installed) == 1) installed else if (isTRUE(ask("AI agent",
          "Which subscription do you have for the course agent: ChatGPT Plus (for Codex) or Claude Pro (for Claude Code)?",
          "ChatGPT Plus", "Claude Pro"))) "codex" else "claude"
  writeLines(id, state_file("agent"))
  a <- agents[[id]]
  # In a codespace the browser cannot reach a sign-in page served inside the
  # container, so Codex signs in with a code instead.
  device <- in_codespace() && id == "codex"
  in_terminal(id, c(a$login, if (device) "--device-auth"))
  tell(a$name, paste0("The Terminal is signing you in to ", a$name, ". ",
                      if (in_codespace()) "Open the link it shows, sign in" else "Sign in in the browser",
                      " with the ", a$account, " account that has your ", a$plan, " subscription",
                      if (in_codespace()) ", and follow the steps it shows" else "",
                      ", then come back here."))
  wait_for(function() list(ok = signed_in(id)), paste(a$name, "sign-in"))
}

kobo_token_from_password <- function() {
  user <- if (rstudioapi::isAvailable()) rstudioapi::showPrompt("KoboToolbox", "KoboToolbox username") else readline("KoboToolbox username: ")
  if (!nzchar(user %||% "")) return("")
  pw <- secret("KoboToolbox password (used once to fetch your key, never saved)")
  h <- curl::new_handle(timeout = 20, httpauth = 1L, userpwd = paste0(user, ":", pw))
  r <- tryCatch(curl::curl_fetch_memory(paste0(kobo_server(), "/token/?format=json"), handle = h),
                error = function(e) NULL)
  if (is.null(r) || r$status_code != 200) return("")
  tryCatch(jsonlite::fromJSON(rawToChar(r$content))$token %||% "", error = function(e) "")
}

setup_kobo <- function() {
  if (check_kobo()$ok) return(invisible())
  # In a codespace the course's own KoboToolbox account serves every pair:
  # its key reaches each codespace as an organization Codespaces secret, so
  # students need no KoboToolbox account of their own.
  if (in_codespace()) {
    tell("KoboToolbox", paste("The course's KoboToolbox key did not reach this codespace.",
                              "You do not need a KoboToolbox account of your own: tell Sifat, and carry on with setup."))
    return(invisible())
  }
  account_first("KoboToolbox", links$kobo_signup)
  tok <- kobo_token_from_password()
  if (!nzchar(tok)) {
    utils::browseURL(paste0(kobo_server(), "/#/account/security"))
    tok <- secret("Could not fetch the key automatically. On the page now open, click Display next to API Key, copy it, and paste it here")
  }
  if (nzchar(tok)) renviron_set("KOBO_API_TOKEN", tok)
}

setup_ipums <- function() {
  r <- check_ipums()
  if (r$ok) return(invisible())
  # As with KoboToolbox, a codespace uses the course's IPUMS account, whose
  # key reaches it as an organization Codespaces secret.
  if (in_codespace()) {
    tell("IPUMS", paste("The course's IPUMS key did not reach this codespace.",
                        "You do not need an IPUMS account of your own: tell Sifat, and carry on with setup."))
    return(invisible())
  }
  if (!grepl("not registered", r$detail)) {
    account_first("IPUMS USA", links$ipums_signup)
    utils::browseURL(links$ipums_keys)
    key <- secret("On the IPUMS page now open, sign in, create an API key, copy it, and paste it here")
    if (nzchar(key)) renviron_set("IPUMS_API_KEY", key)
    r <- check_ipums()
  }
  if (grepl("not registered", r$detail)) {
    utils::browseURL(links$ipums_signup)
    tell("IPUMS USA", paste("Your key works, but your IPUMS account is not yet registered for IPUMS USA.",
                            "Fill in the USA registration page now open, then rerun Course setup once IPUMS approves it."))
  }
}

#' Set up everything the course needs, fixing whatever is missing, then
#' print the pass or fail report. Safe to rerun at any time.
#' @export
setup <- function() {
  tools <- check_tools()
  if (!tools$ok) {
    tell("Programs missing", paste(tools$detail,
         "\nRun the course installer again (see Canvas), then click Addins > Course setup."))
    return(invisible(check()))
  }
  migrate_keys()
  load_keys()
  setup_github()
  setup_agent()
  setup_kobo()
  setup_ipums()
  setup_console_agent()
  sync_course()
  invisible(check())
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
