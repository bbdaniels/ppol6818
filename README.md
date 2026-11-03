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

The installer installs R, RStudio, Git, the GitHub command-line tool, uv, Codex, OpenCode and this package, creates the course folder `Projects/ppol-6818` in the home folder (never in iCloud or OneDrive), and opens it in RStudio. Opening that project runs course setup until every check passes; after that it accepts course invitations and downloads new course repositories into `~/PPOL6818` each time it opens.

## In RStudio

The package In RStudio it adds three entries to the Addins menu:

- **Course setup** checks every sign-in the course needs (GitHub, KoboToolbox, IPUMS USA), the course agent and the course organization. When one is missing it opens the sign-up or key page, then prints a pass or fail report.
- **Course agent** opens OpenCode on a free GLM model in the Terminal, in the current project.
- **Course agent (alternative)** opens Codex, which is installed as the fallback. To make Codex the course default, set `default_agent` in `R/agent.R`.

Both agents can read and deploy KoboToolbox forms through `kobo-mcp`. IPUMS data is downloaded with your own key through `ipumsr`; see `inst/examples/ipums-extract.R`. IPUMS data never goes into a repository.

Install by hand: `install.packages("pak"); pak::pak("bbdaniels/ppol6818")`, then `ppol6818::setup()`.
