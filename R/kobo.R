# KoboToolbox from R: the course's Kobo tools. The agent calls these through
# the RStudio Console like any other R code, and students can call them too.
# They replace the kobo-mcp connector (github.com/bbdaniels/kobo-mcp), whose
# ten tools they port one for one, so the course needs no Python and no
# connector registered with each agent. The key is KOBO_API_TOKEN, which the
# course project loads from the course folder's .Renviron.

xlsx_type <- "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

kobo_token <- function() {
  tok <- Sys.getenv("KOBO_API_TOKEN")
  if (!nzchar(tok)) stop("No KoboToolbox key in this R session. Open the course project, or click Addins > Course setup.", call. = FALSE)
  tok
}

# One request to the KoboToolbox API. `body` is sent as JSON, `form` as a
# multipart upload; `to` saves the response to a file instead of parsing it.
kobo_request <- function(path, method = "GET", query = NULL, body = NULL, form = NULL, to = NULL, timeout = 60) {
  url <- if (grepl("^https?://", path)) path else paste0(kobo_server(), path)
  if (length(query)) {
    query <- query[!vapply(query, is.null, TRUE)]
    url <- paste0(url, if (grepl("?", url, fixed = TRUE)) "&" else "?",
                  paste(names(query), vapply(query, function(v) curl::curl_escape(as.character(v)), ""), sep = "=", collapse = "&"))
  }
  h <- curl::new_handle(timeout = timeout)
  # handle_setheaders replaces any headers set before, so set them all at once.
  headers <- c(Authorization = paste("Token", kobo_token()),
               Accept = if (is.null(to)) "application/json",
               "Content-Type" = if (!is.null(body)) "application/json")
  do.call(curl::handle_setheaders, c(list(h), as.list(headers)))
  if (!is.null(body)) curl::handle_setopt(h, copypostfields = jsonlite::toJSON(body, auto_unbox = TRUE))
  if (!is.null(form)) do.call(curl::handle_setform, c(list(h), form))
  if (method != "GET") curl::handle_setopt(h, customrequest = method)
  if (!is.null(to)) {
    r <- curl::curl_fetch_disk(url, to, handle = h)
    if (r$status_code >= 300) { unlink(to); stop(sprintf("KoboToolbox refused %s %s: HTTP %d", method, path, r$status_code), call. = FALSE) }
    return(invisible(to))
  }
  r <- curl::curl_fetch_memory(url, handle = h)
  txt <- rawToChar(r$content)
  if (r$status_code >= 300)
    stop(sprintf("KoboToolbox refused %s %s: HTTP %d %s", method, path, r$status_code, substr(txt, 1, 300)), call. = FALSE)
  if (!nzchar(txt)) return(invisible(NULL))
  jsonlite::fromJSON(txt, simplifyVector = FALSE)
}

# The API ignores an asset_type parameter and returns every asset, including
# empty drafts and library items; only the q filter selects survey forms.
surveys_query <- function(search = NULL) {
  q <- "asset_type:survey"
  if (length(search) && nzchar(search)) q <- paste0(q, ' AND name__icontains:"', gsub('"', "", search), '"')
  q
}

# Every page of a list endpoint.
kobo_all <- function(path, query = list()) {
  out <- list()
  page <- kobo_request(path, query = c(query, list(limit = 300, format = "json")))
  repeat {
    out <- c(out, page$results)
    if (is.null(page$`next`)) break
    page <- kobo_request(page$`next`)
  }
  out
}

asset_row <- function(a) {
  g <- function(x) if (is.null(x)) NA else x
  data.frame(uid = g(a$uid), name = g(a$name), deployment_status = g(a$deployment_status),
             submission_count = g(a$deployment__submission_count %||% 0L),
             date_created = g(a$date_created), date_modified = g(a$date_modified),
             owner = g(a$owner__username), stringsAsFactors = FALSE)
}

web_link <- function(a) {
  l <- a$deployment__links
  l$url %||% l$offline_url %||% NA_character_
}

#' How to use the course's KoboToolbox functions, with step-by-step workflows.
#' @param topic "overview", "deploy", "translate" or "data".
#' @export
kobo_help <- function(topic = "overview") {
  topic <- match.arg(topic, names(kobo_workflows))
  cat(kobo_workflows[[topic]], "\n")
  invisible(topic)
}

kobo_workflows <- list(
  overview = "KoboToolbox from R (package ppol6818). Your key loads with the course project.

  kobo_forms(search)              Your survey forms: uid, name, status, submission count.
  kobo_form(uid)                  One form, with its questions and choices (content).
  kobo_resolve(url)               The form behind a web form link (ee.kobotoolbox.org/...).
  kobo_download_form(uid, path)   Save a form as an XLSForm (.xlsx) to edit.
  kobo_deploy(path, name)         Upload a NEW XLSForm and make it live; returns its web link.
  kobo_replace(uid, path)         Replace a live form's XLSForm, keeping its uid and submissions.
  kobo_submissions(uid, ...)      Submissions as a data frame (limit, start, query).
  kobo_export(uid, type, path)    Export all submissions to a CSV or XLS file.
  kobo_validate(uid, ids, status) Mark submissions approved, not_approved or on_hold.
  kobo_delete(uid)                Delete a form and its submissions, permanently.

Workflows, step by step: kobo_help(\"deploy\"), kobo_help(\"translate\"), kobo_help(\"data\").",
  deploy = "Deploy a new form

1. Write an XLSForm (.xlsx) with sheets
   survey:   type, name, label (and label::Language (code) columns for translations)
   choices:  list_name, name, label
   settings: form_title, form_id, default_language (optional)
   From R, write it with writexl:
     writexl::write_xlsx(list(survey = survey, choices = choices, settings = settings), \"survey.xlsx\")
   KoboToolbox cannot read .xlsx files written by openxlsx.
2. f <- kobo_deploy(\"survey.xlsx\", \"My survey\")   # f$web_link is the link respondents open
3. Check it: kobo_form(f$uid)$content$survey
To change it later use kobo_replace(f$uid, \"survey.xlsx\"), never kobo_deploy, so the uid and the submissions stay.",
  translate = "Translate an existing form

1. kobo_forms(\"My survey\")                           # note the uid
2. kobo_download_form(uid, \"form.xlsx\")
3. In both the survey and the choices sheets, add a column per language, named
   label::English (en), label::French (fr), hint::French (fr) and so on.
   Keep the name column unchanged: it is each question's internal name.
   The settings sheet can set default_language.
4. kobo_replace(uid, \"form.xlsx\")                     # the uid and all submissions stay",
  data = "Get submissions

Small data or a filter:  d <- kobo_submissions(uid, limit = 100, start = 0, query = '{\"district\": \"Kampala\"}')
                         attr(d, \"count\") is the number of submissions matching, across all pages.
All data, for analysis:  p <- kobo_export(uid, \"csv\", \"survey.csv\"); d <- read.csv(p, sep = \";\")
                         KoboToolbox CSV exports separate columns with semicolons.
Mark test or bad submissions instead of deleting them:
                         kobo_validate(uid, d$`_id`[1:2], \"not_approved\")"
)

#' Your KoboToolbox survey forms.
#' @param search Text to search form names for; all forms when omitted.
#' @return A data frame with one row per form.
#' @export
kobo_forms <- function(search = NULL) {
  a <- kobo_all("/api/v2/assets/", list(q = surveys_query(search)))
  if (!length(a)) return(asset_row(list())[0, ])
  do.call(rbind, lapply(a, asset_row))
}

#' One KoboToolbox form, with its questions and choices.
#' @param uid The form's uid (from kobo_forms()).
#' @return A list; `content$survey` holds the questions, `deployment_links` the web form links.
#' @export
kobo_form <- function(uid) {
  a <- kobo_request(paste0("/api/v2/assets/", uid, "/"), query = list(format = "json"))
  c(as.list(asset_row(a)), list(deployment_links = a$deployment__links, content = a$content))
}

#' The form behind a web form link.
#' @param url A web form link, such as https://ee.kobotoolbox.org/x/AbCd1234.
#' @return A list with the form's uid, name and links.
#' @export
kobo_resolve <- function(url) {
  target <- sub("/+$", "", trimws(url))
  # The form list leaves out each form's links, so read each deployed form.
  for (a in kobo_all("/api/v2/assets/", list(q = surveys_query()))) {
    if (!identical(a$deployment_status, "deployed")) next
    f <- kobo_request(paste0("/api/v2/assets/", a$uid, "/"), query = list(format = "json"))
    if (any(sub("/+$", "", unlist(f$deployment__links)) == target))
      return(list(uid = f$uid, name = f$name, deployment_links = f$deployment__links))
  }
  stop("No form of yours has the link ", url, call. = FALSE)
}

#' Save a KoboToolbox form as an XLSForm (.xlsx) to edit.
#' @param uid The form's uid.
#' @param path Where to save the .xlsx.
#' @return The path, invisibly.
#' @export
kobo_download_form <- function(uid, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  kobo_request(paste0("/api/v2/assets/", uid, ".xls"), to = path)
  message("Saved the form ", uid, " to ", path)
  invisible(path)
}

# Load an XLSForm into an existing form. /api/v2/imports/ is the only endpoint
# that parses the file: posting the file to /api/v2/assets/ makes an empty
# form and ignores the upload, and an import with no destination makes a
# library block, which cannot be deployed.
kobo_import <- function(uid, path) {
  if (!file.exists(path)) stop("No file at ", path, call. = FALSE)
  imp <- kobo_request("/api/v2/imports/", "POST",
                      form = list(destination = paste0(kobo_server(), "/api/v2/assets/", uid, "/"),
                                  file = curl::form_file(path, type = xlsx_type)))
  for (i in 1:60) {
    s <- kobo_request(paste0("/api/v2/imports/", imp$uid, "/"), query = list(format = "json"))
    if (identical(s$status, "complete")) break
    if (identical(s$status, "error"))
      stop("KoboToolbox could not read the XLSForm: ", jsonlite::toJSON(s$messages, auto_unbox = TRUE), call. = FALSE)
    if (i == 60) stop("KoboToolbox is still reading the XLSForm after a minute; check the form ", uid, " on the website.", call. = FALSE)
    Sys.sleep(1)
  }
  a <- kobo_request(paste0("/api/v2/assets/", uid, "/"), query = list(format = "json"))
  if (!length(a$content$survey)) stop("The form ", uid, " has no questions after the upload; not deploying it.", call. = FALSE)
  a
}

#' Upload a new XLSForm to KoboToolbox and make it live.
#'
#' To change a form that is already live, use kobo_replace(), which keeps its
#' uid and submissions.
#' @param path The XLSForm (.xlsx).
#' @param name The form's name; the file name when omitted.
#' @return A list with the form's uid, name, web_link (for respondents) and manage_link.
#' @export
kobo_deploy <- function(path, name = tools::file_path_sans_ext(basename(path))) {
  if (!file.exists(path)) stop("No file at ", path, call. = FALSE)
  uid <- kobo_request("/api/v2/assets/", "POST", body = list(name = name, asset_type = "survey"))$uid
  # A failed upload would otherwise leave an empty draft form on the account.
  tryCatch(kobo_import(uid, path), error = function(e) {
    try(kobo_request(paste0("/api/v2/assets/", uid, "/"), "DELETE"), silent = TRUE)
    stop(e)
  })
  kobo_request(paste0("/api/v2/assets/", uid, "/deployment/"), "POST", body = list(active = TRUE))
  a <- kobo_request(paste0("/api/v2/assets/", uid, "/"), query = list(format = "json"))
  list(uid = uid, name = name, web_link = web_link(a), manage_link = paste0(kobo_server(), "/#/forms/", uid))
}

#' Replace a live form's XLSForm, keeping its uid and submissions.
#' @param uid The form's uid.
#' @param path The new XLSForm (.xlsx).
#' @return A list with the form's uid, name, submission_count, web_link and manage_link.
#' @export
kobo_replace <- function(uid, path) {
  a <- kobo_import(uid, path)
  kobo_request(paste0("/api/v2/assets/", uid, "/deployment/"), "PATCH",
               body = list(active = TRUE, version_id = a$version_id))
  a <- kobo_request(paste0("/api/v2/assets/", uid, "/"), query = list(format = "json"))
  list(uid = uid, name = a$name, submission_count = a$deployment__submission_count %||% 0L,
       web_link = web_link(a), manage_link = paste0(kobo_server(), "/#/forms/", uid))
}

#' Submissions to a form, as a data frame.
#' @param uid The form's uid.
#' @param limit,start How many submissions, from which position.
#' @param query A MongoDB-style JSON filter, such as '{"district": "Kampala"}'.
#' @return A data frame; attr(, "count") is the number of matching submissions across all pages.
#' @export
kobo_submissions <- function(uid, limit = 100, start = 0, query = NULL) {
  url <- paste0(kobo_server(), "/api/v2/assets/", uid, "/data/?format=json&limit=", limit, "&start=", start,
                if (!is.null(query)) paste0("&query=", curl::curl_escape(query)) else "")
  h <- curl::new_handle(timeout = 60)
  curl::handle_setheaders(h, Authorization = paste("Token", kobo_token()))
  r <- curl::curl_fetch_memory(url, handle = h)
  if (r$status_code >= 300) stop(sprintf("KoboToolbox refused the submissions of %s: HTTP %d", uid, r$status_code), call. = FALSE)
  j <- jsonlite::fromJSON(rawToChar(r$content), flatten = TRUE)
  d <- if (length(j$results)) as.data.frame(j$results, stringsAsFactors = FALSE) else data.frame()
  attr(d, "count") <- j$count %||% 0L
  d
}

#' Export all of a form's submissions to a file.
#' @param uid The form's uid.
#' @param type "csv" or "xls". KoboToolbox CSV files separate columns with semicolons.
#' @param path Where to save the export.
#' @param labels Column headers from the question labels (TRUE) or names (FALSE).
#' @return The path, invisibly.
#' @export
kobo_export <- function(uid, type = c("csv", "xls"), path = paste0(uid, ".", type), labels = FALSE) {
  type <- match.arg(type)
  e <- kobo_request(paste0("/api/v2/assets/", uid, "/exports/"), "POST",
                    body = list(fields_from_all_versions = TRUE, group_sep = "/", hierarchy_in_labels = labels,
                                lang = if (labels) "_default" else "_xml", multiple_select = "both", type = type))
  for (i in 1:60) {
    s <- kobo_request(paste0("/api/v2/assets/", uid, "/exports/", e$uid, "/"), query = list(format = "json"))
    if (identical(s$status, "complete")) break
    if (identical(s$status, "error")) stop("KoboToolbox could not export ", uid, ": ", jsonlite::toJSON(s$messages, auto_unbox = TRUE), call. = FALSE)
    if (i == 60) stop("The export of ", uid, " is still running after a minute; try again shortly.", call. = FALSE)
    Sys.sleep(1)
  }
  kobo_request(s$result, to = path)
  message("Saved the submissions of ", uid, " to ", path)
  invisible(path)
}

#' Mark submissions approved, not approved or on hold.
#' @param uid The form's uid.
#' @param ids The submissions' `_id` values.
#' @param status "approved", "not_approved" or "on_hold".
#' @export
kobo_validate <- function(uid, ids, status = c("approved", "not_approved", "on_hold")) {
  status <- match.arg(status)
  if (!length(ids)) stop("No submission ids given.", call. = FALSE)
  kobo_request(paste0("/api/v2/assets/", uid, "/data/validation_statuses/"), "PATCH",
               body = list(payload = list(submission_ids = I(as.integer(ids)),
                                          `validation_status.uid` = paste0("validation_status_", status))))
  message(sprintf("Marked %d submissions of %s %s", length(ids), uid, status))
  invisible(ids)
}

#' Delete a form and all its submissions, permanently.
#' @param uid The form's uid.
#' @export
kobo_delete <- function(uid) {
  kobo_request(paste0("/api/v2/assets/", uid, "/"), "DELETE")
  message("Deleted the form ", uid)
  invisible(uid)
}
