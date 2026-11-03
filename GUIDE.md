# PPOL 6818 setup guide

You will do all of your coding for this course in RStudio, with an AI coding agent beside you in RStudio's Terminal. Setup takes about half an hour, most of it waiting for downloads, and is due Sunday, January 17, 2027.

## 1. Create four accounts

Use your Georgetown email address for each one.

- **GitHub** (https://github.com/signup). Then apply for GitHub Education (https://github.com/settings/education/benefits) with your Georgetown email; approval can take a few days, and setup works before it arrives.
- **ChatGPT** (https://chatgpt.com), then claim Codex for Students (https://chatgpt.com/codex/students). Codex is the coding agent you will use most.
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
  Codex sign-in                      PASS
  KoboToolbox key                    PASS
  IPUMS key                          PASS
  Agents connected to KoboToolbox    PASS
  Course organization                WAIT  not invited yet
```

Copy the whole check, with your GitHub username, into the Setup assignment on Canvas. WAIT on the last line is expected: we invite you to the course organization on GitHub after we see your check. If any line says FAIL, click **Addins > Course setup** in RStudio's toolbar to try that step again, and bring the check to office hours if that step fails again.

## 4. Join the course organization

After we invite you, open the `PPOL6818` project in RStudio again (File, Recent Projects). RStudio accepts the invitation and downloads each new course repository into the `PPOL6818` folder. RStudio repeats this every time you open a course project. New repositories for later assignments arrive the same way.

## Working with the agents

Click **Addins > Course agent** to open Codex in RStudio's Terminal, in the project you have open. Ask it in plain English to write, run and check code. The agents read the course rules from the file `AGENTS.md` in each repository: they write code and show you evidence that it worked, and they do not write the prose you submit.

Codex for Students includes a monthly allowance. When Codex says you are out of credits, quit it (type `/quit`) and click **Addins > Course agent (free)**. That opens OpenCode on a free model, with the same KoboToolbox connection and the same course rules.

## Data

Your IPUMS data never goes into a repository; the IPUMS terms do not allow sharing it. Each repository has a `run.R` that downloads your extract with your own key into a `data` folder that Git ignores. Your KoboToolbox forms live in your own KoboToolbox account, and both agents can create, deploy and read them for you.
