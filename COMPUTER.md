# RStudio on your own computer

The course itself uses only the codespace; this guide is for using R on your own computer after the course.

This is optional and not part of the course's setup: the course runs in your codespace, and every lab is written for it. Use this page if you want R, RStudio and an AI coding agent on your own Mac or Windows computer, for your own work during the term or after it. It works offline and has no hours limit.

Your own computer does not get the course's IPUMS and KoboToolbox keys, which reach codespaces only, so here you use your own accounts. Make them first, with your personal email address:

- **IPUMS USA** (https://uma.pop.umn.edu/usa/user/new). Approval usually arrives by email within a day.
- **KoboToolbox** (https://kf.kobotoolbox.org/accounts/signup/), on the global server.

Your pair's survey forms live on the course's KoboToolbox account, so build and deploy them in the codespace; forms you make on your computer go to your own account.

## Install

On a Mac, open Terminal (in Applications, Utilities), paste this line and press Return:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-mac.sh)"
```

On Windows, open PowerShell from the Start menu, paste this line and press Enter:

```
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-windows.ps1 | iex"
```

On a Mac the installer asks for your computer password once (it does not show as you type); on Windows, click Yes when Windows asks to allow changes. The installer then installs R, RStudio, Git, the GitHub tools, Codex, Claude Code and the course R package. Anything already on your computer is kept. When it finishes, RStudio opens the course folder, `ppol-6818` inside the `Projects` folder in your home folder (setup makes `Projects` if you do not have one). Keep it there: course folders must not be in iCloud, OneDrive or another synced folder, because syncing damages Git repositories.

## Finish in RStudio

RStudio then walks you through each sign-in in turn: GitHub, your agent, and your own KoboToolbox and IPUMS keys. Each time it opens a browser page, you sign in or copy a key, and you come back to RStudio. It then downloads your course repositories into the `ppol-6818` folder, and does so again each time you open a course project. It ends with the same check as the codespace; you do not submit this one.

Your work lives in your GitHub repositories, so you can move between the codespace and your computer: push before you leave one, and pull when you arrive at the other. On your computer, `ipums_get()` makes each extract on your own IPUMS account, so a lab's first data download can take a few minutes longer than in the codespace, where the course made the extract the day before.
