# PPOL 6818 setup guide

You will do all of your coding for this course in RStudio, with an AI coding agent beside you in RStudio's Terminal. Setup takes about half an hour, most of it waiting for downloads, and is due Sunday, January 17, 2027.

## 1. Create three accounts

Use your personal email address for each one, so that you keep the accounts after you leave Georgetown.

- **GitHub** (https://github.com/signup). Then add your Georgetown email to your GitHub account as a second address (https://github.com/settings/emails) and apply for GitHub Education (https://github.com/settings/education/benefits) with it; approval can take a few days, and setup works before it arrives.
- **IPUMS USA** (https://uma.pop.umn.edu/usa/user/new). Approval usually arrives by email within a day.
- **KoboToolbox** (https://kf.kobotoolbox.org/accounts/signup/), on the global server.

If you skip one, setup opens its sign-up page when it gets there.

## 2. Run the installer

On a Mac, open Terminal (in Applications, Utilities), paste this line and press Return:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-mac.sh)"
```

On Windows, open PowerShell from the Start menu, paste this line and press Enter:

```
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-windows.ps1 | iex"
```

On a Mac the installer asks for your computer password once (it does not show as you type); on Windows, click Yes when Windows asks to allow changes. The installer then installs R, RStudio, Git, the GitHub tools, Codex, OpenCode and the course R package. Anything already on your computer is kept. When it finishes, RStudio opens the course folder, `PPOL6818` in your home folder.

## 3. Finish setup in RStudio

RStudio continues where the installer stopped. It walks you through each sign-in in turn: it opens a browser page, you sign in or copy a key, and you come back to RStudio. At the end it prints a check like this one:

```
PPOL 6818 setup check
  Programs installed                 PASS
  GitHub sign-in                     PASS  your-username
  Course agent                       PASS
  KoboToolbox key                    PASS
  IPUMS key                          PASS
  Agents connected to KoboToolbox    PASS
  Course organization                WAIT  not invited yet
```

Copy the whole check, with your GitHub username, into the Setup assignment on Canvas. WAIT on the last line is expected: we invite you to the course organization on GitHub after we see your check. If any line says FAIL, click **Addins > Course setup** in RStudio's toolbar to try that step again, and bring the check to office hours if that step fails again.

## 4. Join the course organization

After we invite you, open the `PPOL6818` project in RStudio again (File, Recent Projects). RStudio accepts the invitation and downloads each new course repository into the `PPOL6818` folder. RStudio repeats this every time you open a course project. New repositories for later assignments arrive the same way.

## Working with the agents

Click **Addins > Course agent** to open the course agent (OpenCode, on a free model) in RStudio's Terminal, in the project you have open. It needs no account. Ask it in plain English to write, run and check code. The agent reads the course rules from the file `AGENTS.md` in each repository: it writes code and shows you evidence that it worked, and it does not write the prose you submit.

The installer also installs Codex, a second agent. If we switch the course to Codex during the semester, we will tell you, and setup will ask you to sign in to it.

## Data

Your course repositories are private; only the minisite you publish from them is public. Your IPUMS data never goes into a repository, because the IPUMS terms do not allow sharing it. Each repository has a `run.R` that downloads your extract with your own key into a `data` folder that Git ignores. Your KoboToolbox forms live in your own KoboToolbox account, and the agent can create, deploy and read them for you.
