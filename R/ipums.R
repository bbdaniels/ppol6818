# IPUMS USA from R: one function owns every extract a student or pair uses.
#
# The student (or the agent) writes the definition in run.R: the samples, the
# variables, and which people to keep, as IPUMS case selections, so IPUMS cuts
# the data before it is downloaded. ipums_get() then
#   1. reuses the saved copy when the definition has not changed;
#   2. otherwise reuses an extract the course account already made from the
#      same definition (in a codespace every student shares the course's
#      IPUMS account, so the class's week 2 extract is made once), or submits
#      a new one and waits for it;
#   3. downloads it as compressed CSV, converts it once to Parquet with
#      DuckDB (streaming, so a large file never has to fit in memory), keeps
#      the codebook, and deletes the download;
#   4. replaces any older copy under the same name, and reports the size.
# ipums_read() then reads only the columns and rows asked for.
#
# The data stay in the project's data/ folder, which .gitignore keeps out of
# the repository and the minisite: microdata is never published.

ipums_dir <- function(dir) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  normalizePath(dir)
}

# A short fingerprint of the definition, independent of its description.
extract_hash <- function(def) {
  def$description <- "ppol6818"
  f <- tempfile(fileext = ".json")
  on.exit(unlink(f))
  ipumsr::save_extract_as_json(def, f)
  substr(unname(tools::md5sum(f)), 1, 10)
}

ipums_key <- function() {
  if (!nzchar(Sys.getenv("IPUMS_API_KEY")))
    stop("No IPUMS key in this R session. ",
         if (in_codespace()) "The course key reaches every codespace; tell Sifat it is missing."
         else "Click Addins > Course setup.", call. = FALSE)
}

# A finished extract on the account made from the same definition, if any.
find_extract <- function(hash, how_many = 200) {
  hist <- tryCatch(ipumsr::get_extract_history("usa", how_many = how_many), error = function(e) list())
  for (ext in hist) {
    if (grepl(paste0("[", hash, "]"), ext$description, fixed = TRUE) && ipumsr::is_extract_ready(ext))
      return(ext)
  }
  NULL
}

#' Get an IPUMS USA extract as a Parquet file in the project's data folder.
#'
#' @param name A short name for the extract, such as "acs_border". Rerunning
#'   with a changed definition replaces the copy saved under this name.
#' @param samples IPUMS USA sample ids, such as c("us2012a", "us2013a").
#' @param variables Variable names, or `ipumsr::var_spec()` calls for case
#'   selections, such as `ipumsr::var_spec("STATEFIP", case_selections = c("21", "47"))`.
#' @param ... Passed to `ipumsr::define_extract_micro()` (for example
#'   `data_quality_flags = TRUE`).
#' @param dir Where the data go, relative to the project.
#' @return The Parquet file's path, invisibly.
#' @export
ipums_get <- function(name, samples, variables, ..., dir = "data/ipums") {
  stopifnot(grepl("^[A-Za-z0-9_]+$", name))
  ipums_key()
  dir <- ipums_dir(dir)
  pq <- file.path(dir, paste0(name, ".parquet"))
  meta_file <- file.path(dir, paste0(name, ".json"))
  def <- ipumsr::define_extract_micro("usa", description = "ppol6818", samples = samples,
                                      variables = variables, data_format = "csv", ...)
  hash <- extract_hash(def)
  if (file.exists(pq) && file.exists(meta_file) &&
      identical(jsonlite::read_json(meta_file)$hash, hash)) {
    return(invisible(pq))
  }
  def$description <- sprintf("ppol6818 %s [%s]", name, hash)

  ext <- find_extract(hash)
  if (is.null(ext)) {
    message("Submitting IPUMS extract '", name, "'. IPUMS usually takes a few minutes.")
    ext <- ipumsr::wait_for_extract(ipumsr::submit_extract(def), verbose = FALSE)
  } else {
    message("Reusing IPUMS extract ", ext$number, ", made earlier from the same definition.")
  }
  tmp <- tempfile("ipums")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  ddi <- tryCatch(ipumsr::download_extract(ext, download_dir = tmp, progress = FALSE),
                  error = function(e) NULL)
  if (is.null(ddi)) {
    # Its files had expired: make it again.
    ext <- ipumsr::wait_for_extract(ipumsr::submit_extract(def), verbose = FALSE)
    ddi <- ipumsr::download_extract(ext, download_dir = tmp, progress = FALSE)
  }
  csv <- list.files(tmp, pattern = "\\.csv(\\.gz)?$", full.names = TRUE)
  if (length(csv) != 1) stop("The IPUMS download has no single CSV file: ", paste(list.files(tmp), collapse = ", "))

  con <- duckdb_con()
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  part <- paste0(pq, ".part")
  DBI::dbExecute(con, sprintf("COPY (SELECT * FROM read_csv(%s)) TO %s (FORMAT parquet, COMPRESSION zstd)",
                              sql_str(csv), sql_str(part)))
  file.rename(part, pq)
  file.copy(ddi, file.path(dir, paste0(name, ".xml")), overwrite = TRUE)
  rows <- DBI::dbGetQuery(con, sprintf("SELECT count(*) AS n FROM read_parquet(%s)", sql_str(pq)))$n
  jsonlite::write_json(list(hash = hash, extract = ext$number, samples = samples,
                            variables = names(def$variables), rows = rows,
                            made = format(Sys.time(), "%Y-%m-%d %H:%M")),
                       meta_file, auto_unbox = TRUE, pretty = TRUE)
  message(sprintf("IPUMS extract '%s': %s rows, %s on disk in %s",
                  name, format(rows, big.mark = ","), human_size(file.size(pq)), pq))
  invisible(pq)
}

#' Read an IPUMS extract saved by ipums_get(), only the columns and rows you need.
#'
#' @param name The extract's name.
#' @param columns Column names to keep (all when NULL).
#' @param where A SQL condition on the rows, such as "AGE BETWEEN 19 AND 64 AND STATEFIP IN (21, 47)".
#' @param dir Where ipums_get() saved it.
#' @return A data frame.
#' @export
ipums_read <- function(name, columns = NULL, where = NULL, dir = "data/ipums") {
  pq <- file.path(dir, paste0(name, ".parquet"))
  if (!file.exists(pq)) stop("No extract named '", name, "' in ", dir, ". Run its ipums_get() first.", call. = FALSE)
  con <- duckdb_con()
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  cols <- if (length(columns)) paste(sprintf('"%s"', columns), collapse = ", ") else "*"
  sql <- sprintf("SELECT %s FROM read_parquet(%s)%s", cols, sql_str(pq),
                 if (length(where) && nzchar(where)) paste(" WHERE", where) else "")
  DBI::dbGetQuery(con, sql)
}

#' The value labels of one variable in a saved IPUMS extract, from its codebook.
#' @param name The extract's name.
#' @param var The variable, such as "HCOVANY".
#' @param dir Where ipums_get() saved it.
#' @export
ipums_labels <- function(name, var, dir = "data/ipums") {
  ddi <- ipumsr::read_ipums_ddi(file.path(dir, paste0(name, ".xml")))
  ipumsr::ipums_val_labels(ddi, var)
}

duckdb_con <- function() {
  con <- DBI::dbConnect(duckdb::duckdb(shared_home = FALSE))
  # Keep well inside a codespace's memory; DuckDB spills to disk beyond it.
  DBI::dbExecute(con, "SET memory_limit = '2GB'")
  DBI::dbExecute(con, sprintf("SET temp_directory = %s", sql_str(tempdir())))
  con
}

sql_str <- function(x) paste0("'", gsub("'", "''", x), "'")

human_size <- function(bytes) {
  u <- c("B", "KB", "MB", "GB")
  i <- max(1, min(4, floor(log(max(bytes, 1), 1024)) + 1))
  sprintf("%.1f %s", bytes / 1024^(i - 1), u[i])
}

# The setup check's line: how much course data sits in this codespace or
# course folder. Codespace storage counts every file, and each student's
# allowance is about 15 GB, of which the course image uses about 8.
check_data <- function() {
  roots <- if (in_codespace()) list.dirs("/workspaces", recursive = FALSE) else course_dir()
  roots <- roots[!grepl("/\\.", roots)]
  data <- unlist(lapply(roots, function(r) list.files(file.path(r, "data"), recursive = TRUE, full.names = TRUE)))
  total <- sum(file.size(data), na.rm = TRUE)
  if (total > 3 * 1024^3)
    return(list(ok = FALSE, detail = paste(human_size(total), "of data: delete extracts you no longer use, or narrow them with case selections")))
  list(ok = TRUE, detail = paste(human_size(total), "of data"))
}
