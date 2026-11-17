# The pair minisite: a Quarto project at the repository root (the template's
# _quarto.yml) that renders the landing page and the deck into docs/, the
# only folder GitHub Pages publishes. RStudio ships its own Quarto, so the
# course installs nothing more for it.

quarto_path <- function() {
  hit <- find_tool("quarto")
  if (nzchar(hit)) return(hit)
  env <- Sys.getenv(c("QUARTO_PATH", "RSTUDIO_QUARTO"))
  env <- env[nzchar(env) & file.exists(env)]
  if (length(env)) return(unname(env[1]))
  bundled <- c("/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto",
               file.path(Sys.getenv(c("ProgramFiles", "LOCALAPPDATA")), "RStudio", "resources", "app", "bin", "quarto", "bin", "quarto.exe"),
               "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe")
  bundled <- bundled[file.exists(bundled)]
  if (length(bundled)) normalizePath(bundled[1]) else ""
}

# The repository's address on GitHub, from its git remote, for the landing
# page's Repository link.
repo_url <- function() {
  r <- run_tool("git", c("remote", "get-url", "origin"))
  if (r$status != 0) return("")
  u <- sub("\\.git$", "", trimws(r$out))
  sub("^git@github.com:", "https://github.com/", u)
}

#' Build the minisite into docs/: the landing page and the deck. Run it from
#' the repository (Addins > Build minisite), then commit and push docs/.
#' @export
build_site <- function(path = ".") {
  if (!file.exists(file.path(path, "_quarto.yml")))
    stop("No _quarto.yml here: open your pair's project repository first.", call. = FALSE)
  q <- quarto_path()
  if (!nzchar(q)) stop("Quarto was not found. Update RStudio (Help > Check for Updates), which includes it.", call. = FALSE)
  old <- Sys.getenv("REPO_URL")
  Sys.setenv(REPO_URL = repo_url())
  on.exit(Sys.setenv(REPO_URL = old))
  owd <- setwd(path); on.exit(setwd(owd), add = TRUE)
  status <- system2(q, "render")
  if (status != 0) stop("The minisite did not build; the messages above say why.", call. = FALSE)
  file.create(file.path("docs", ".nojekyll"))  # GitHub Pages serves the files as they are
  site <- sub("^https://github.com/([^/]+)/(.+)$", "https://\\1.github.io/\\2/", repo_url())
  message("Built docs/. After you commit and push it, the minisite is at ", site,
          " (GitHub takes about a minute to publish).")
  if (rstudioapi::isAvailable() && file.exists("docs/index.html")) utils::browseURL("docs/index.html")
  invisible(site)
}
