# ppol6818

Course setup and AI agent launcher for PPOL 6818, Policy Research Design (Georgetown, spring 2027).

## Install

Mac, in Terminal:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-mac.sh)"
```

Windows, in PowerShell:

```
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-windows.ps1 | iex"
```

The installer installs R, RStudio, Git, the GitHub command-line tool, Codex and this package, creates the course folder `Projects/ppol-6818` in the home folder (never in iCloud or OneDrive), and opens it in RStudio. Opening that project runs course setup until every check passes; after that it accepts course invitations and downloads new course repositories into the course folder each time it opens.

## In RStudio

The package adds two entries to RStudio's Addins menu:

- **Course setup** checks every sign-in the course needs (GitHub, Codex, KoboToolbox, IPUMS USA), Codex's connection to RStudio and the course organization. When one is missing it opens the sign-up or key page, then prints a pass or fail report.
- **Course agent** opens Codex, the course AI agent, in the Terminal, in the current project. Opening the course folder in RStudio does this by itself, after setup.

Codex runs R in the student's RStudio session through the `rstudio` connector (`R/console.R`, built on `mcptools`): code goes through the Console, so it is echoed there and its objects and plots appear in the Environment and Plots panes. Codex reaches KoboToolbox through the same Console, with the package's `kobo_*` functions (`R/kobo.R`: list, read, deploy, replace and delete forms; fetch, export and validate submissions; `kobo_help()` lists them with workflows), which students can also call themselves, so the course needs no Python and no KoboToolbox key in Codex's configuration. IPUMS data is downloaded with your own key through `ipumsr`; see `inst/examples/ipums-extract.R`. IPUMS data never goes into a repository.

Install by hand: `install.packages("pak"); pak::pak("bbdaniels/ppol6818")`, then `ppol6818::setup()`.
