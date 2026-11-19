# ppol6818

Course setup and AI agent launcher for PPOL 6818, Policy Research Design (Georgetown, spring 2027).

## In the course codespace

Students work in desktop VS Code connected to a GitHub codespace built from the course image (`ppol-6818-2027/course-image`), which installs this package; `GUIDE.md` is the student setup guide and `GITHUB.md` the guide to commits, pushes, the minisite and submission. In the codespace:

- **The R console** is VS Code's default terminal. The repository's `.Rprofile` runs `load_keys()`, then `console_attach()`, which makes the console reachable by the agents, and `on_open()`, which accepts course invitations and downloads new course repositories. `connect_agents()` registers the `r-console` connector with Claude Code and Codex at user scope, once per codespace start, so both VS Code agent extensions reach the console without any folder settings.
- **The course panel** (the course VS Code extension, in the image) has three buttons, each run in the R console: **Course setup** (`setup()`), **Build minisite** (`build_site()`) and **Check** (`check()`).
- **The connector** (`R/console.R`, built on `mcptools`) gives the agent two tools: run code in the R console, optionally in a named repository folder (the folder is restored afterwards), and read the console's last output. The code and what it prints show in the console, and its objects stay in the student's session. With several consoles open, the newest ends the one it replaces, so the agent always finds one.

The agent reaches KoboToolbox through the same console, with the package's `kobo_*` functions (`R/kobo.R`: list, read, deploy, replace and delete forms; fetch, export and validate submissions; `kobo_help()` lists them with workflows), which students can also call themselves, so the course needs no Python and no KoboToolbox key in the agent's configuration. IPUMS data is downloaded through the course's IPUMS account with `ipums_get()`; see `inst/examples/ipums-extract.R`. IPUMS data never goes into a repository.

## On a student's own computer (optional)

`COMPUTER.md` is for students who want R and an agent on their own computer after the course. Mac, in Terminal:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-mac.sh)"
```

Windows, in PowerShell:

```
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-windows.ps1 | iex"
```

The installer installs R, RStudio, Git, the GitHub command-line tool, Codex, Claude Code and this package, creates the course folder `Projects/ppol-6818` in the home folder (never in iCloud or OneDrive), and opens it in RStudio, where setup runs until every check passes. There `agent()` opens the agent in RStudio's Terminal and passes it the connector on its command line (Codex `-c` overrides, Claude Code `--mcp-config`), so the agent's other sessions never start it.

Install by hand: `install.packages("pak"); pak::pak("bbdaniels/ppol6818")`, then `ppol6818::setup()`.
