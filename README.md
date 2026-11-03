# ppol6818

Course setup and AI agent launcher for PPOL 6818, Policy Research Design (Georgetown, spring 2027).

The course installer installs this package. In RStudio it adds three entries to the Addins menu:

- **Course setup** checks every sign-in the course needs (GitHub, Codex, KoboToolbox, IPUMS USA). When one is missing it opens the sign-up or key page, then prints a pass or fail report.
- **Course agent** opens Codex in the Terminal, or the free agent (OpenCode) when Codex is not signed in.
- **Course agent (free)** opens the free agent. Use it when Codex says your credits are used up.

Both agents can read and deploy KoboToolbox forms through `kobo-mcp`. IPUMS data is downloaded with your own key through `ipumsr`; see `inst/examples/ipums-extract.R`. IPUMS data never goes into a repository.

Install by hand: `install.packages("pak"); pak::pak("bbdaniels/ppol6818")`, then `ppol6818::setup()`.
