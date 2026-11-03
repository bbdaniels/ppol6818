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

The installer installs R, RStudio, Git, the GitHub command-line tool, uv, Codex, OpenCode and this package, creates the course folder `~/PPOL6818`, and opens it in RStudio. Opening that project runs course setup until every check passes; after that it accepts course invitations and downloads new course repositories into `~/PPOL6818` each time it opens.

## In RStudio

The package In RStudio it adds three entries to the Addins menu:

- **Course setup** checks every sign-in the course needs (GitHub, Codex, KoboToolbox, IPUMS USA) and the course organization. When one is missing it opens the sign-up or key page, then prints a pass or fail report.
- **Course agent** opens Codex in the Terminal, or the free agent (OpenCode) when Codex is not signed in.
- **Course agent (free)** opens the free agent. Use it when Codex says your credits are used up.

Both agents can read and deploy KoboToolbox forms through `kobo-mcp`. IPUMS data is downloaded with your own key through `ipumsr`; see `inst/examples/ipums-extract.R`. IPUMS data never goes into a repository.

Install by hand: `install.packages("pak"); pak::pak("bbdaniels/ppol6818")`, then `ppol6818::setup()`.
