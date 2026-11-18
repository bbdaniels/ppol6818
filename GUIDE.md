# PPOL 6818 setup guide

You will do all of your coding for this course in RStudio, with an AI coding agent beside you in RStudio's Terminal. RStudio can run in two places, and both give you the same RStudio, the same agent and the same course tools:

- **In the browser**, in a GitHub codespace: a computer GitHub runs for you, with everything already installed. Nothing goes on your own computer, and any computer with a current browser works. GitHub's free allowance covers about 60 hours a month of a course codespace, and about 90 with GitHub Education.
- **On your computer**: an installer puts R, RStudio and the course tools on your Mac or Windows computer. It works offline and has no hours limit.

You can switch at any time, since your work lives in your GitHub repositories either way. Setup takes about half an hour (less in the browser) and is due Sunday, January 17, 2027.

## 1. Create four accounts

Use your personal email address for each one, so that you keep the accounts after you leave Georgetown.

- **GitHub** (https://github.com/signup). Then add your Georgetown email to your GitHub account as a second address (https://github.com/settings/emails) and apply for GitHub Education (https://github.com/settings/education/benefits) with it; approval can take a few days, and setup works before it arrives.
- **An AI agent subscription**, required from the first class: either ChatGPT Plus ($20 a month, https://chatgpt.com/pricing), which runs Codex, or Claude Pro ($20 a month, https://claude.com/pricing), which runs Claude Code. Either one is the course's AI coding agent; you need only one. If you choose ChatGPT, also claim Codex for Students (https://chatgpt.com/codex/students) on the same account with your Georgetown email: it adds extra Codex usage for when you reach Plus's limits.
- **IPUMS USA** (https://uma.pop.umn.edu/usa/user/new). Approval usually arrives by email within a day.
- **KoboToolbox** (https://kf.kobotoolbox.org/accounts/signup/), on the global server.

If you skip one, setup opens its sign-up page when it gets there.

## 2. Open RStudio

### In the browser

Sign in to GitHub and open https://codespaces.new/ppol-6818-2027/template, then click **Create codespace**. A code editor opens in the browser; if it asks whether you trust the folder's authors, click **Trust Folder & Continue**. After about a minute RStudio opens in a new browser tab, on the course project. If your browser blocks the new tab, click **Ports** at the bottom of the editor and then the globe beside **RStudio**. You are signed in to GitHub already, so setup skips that step.

The codespace stops by itself after 30 idle minutes and keeps your files. To come back, open https://github.com/codespaces and click the codespace's name; make a new one only for a new repository. GitHub deletes a codespace after 30 days unused, so push your work to GitHub before you leave it. Stored codespaces also count against a monthly storage allowance (15 GB, or 20 with GitHub Education), so delete one there once its repository's work is pushed and done.

### On your computer

On a Mac, open Terminal (in Applications, Utilities), paste this line and press Return:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-mac.sh)"
```

On Windows, open PowerShell from the Start menu, paste this line and press Enter:

```
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-windows.ps1 | iex"
```

On a Mac the installer asks for your computer password once (it does not show as you type); on Windows, click Yes when Windows asks to allow changes. The installer then installs R, RStudio, Git, the GitHub tools, Codex, Claude Code and the course R package. Anything already on your computer is kept. When it finishes, RStudio opens the course folder, `ppol-6818` inside the `Projects` folder in your home folder (setup makes `Projects` if you do not have one). Keep it there: course folders must not be in iCloud, OneDrive or another synced folder, because syncing damages Git repositories.

## 3. Finish setup in RStudio

RStudio continues where the installer stopped, or where the codespace opened. It walks you through each sign-in in turn: it opens a browser page, you sign in or copy a key, and you come back to RStudio. For the AI agent it asks which subscription you have, ChatGPT Plus or Claude Pro, and signs you in to that agent in RStudio's Terminal. At the end it prints a check like this one:

```
PPOL 6818 setup check
  Programs installed                 PASS
  Course folder                      PASS
  GitHub sign-in                     PASS  your-username
  AI agent sign-in                   PASS  Codex signed in
  KoboToolbox key                    PASS
  IPUMS key                          PASS
  Agent connected to RStudio         PASS
  Course organization                WAIT  not invited yet
```

In the browser, setup asks for your IPUMS and KoboToolbox keys again in each new codespace. To skip that, save them once as Codespaces secrets at https://github.com/settings/codespaces (**New secret**): `IPUMS_API_KEY` and `KOBO_API_TOKEN`, each with access to the repositories in `ppol-6818-2027`. Every codespace you open then has them.

Copy the whole check, with your GitHub username, into the Setup assignment on Canvas. WAIT on the last line is expected: we invite you to the course organization on GitHub after we see your check. If any line says FAIL, click **Addins > Course setup** in RStudio's toolbar to try that step again, and bring the check to office hours if that step fails again.

## 4. Join the course organization

After we invite you, GitHub emails you an invitation to the course organization.

In the browser, accept it at https://github.com/orgs/ppol-6818-2027/invitation, then open each course repository from https://github.com/ppol-6818-2027 (**Code**, **Codespaces**, **Create codespace on main**). Each repository gets its own codespace, with RStudio open on its project.

On your computer, open the `ppol-6818` project in RStudio again (File, Recent Projects). RStudio accepts the invitation and downloads each new course repository into the `ppol-6818` folder. RStudio repeats this every time you open a course project. New repositories for later assignments arrive the same way.

## Working with the agent

The course agent, Codex or Claude Code, opens in RStudio's Terminal every time RStudio opens the course folder. If you close it, click **Addins > Course agent** to open it again, in the project you have open. It uses the account you signed in with during setup. Ask it in plain English to write, run and check code. It runs its code in RStudio's Console, as if you had pressed Run: you see the code and what it prints in the Console, the objects it makes in the Environment pane and its plots in the Plots pane. The agent reads the course rules from the file `AGENTS.md` in each repository (Claude Code reaches it through `CLAUDE.md`): it writes code and shows you evidence that it worked, and it does not write the prose you submit.

## Data

Your course repositories are private; only the minisite you publish from them is public. Your IPUMS data never goes into a repository, because the IPUMS terms do not allow sharing it. Each repository has a `run.R` that downloads your extract with your own key into a `data` folder that Git ignores. Your KoboToolbox forms live in your own KoboToolbox account, and the agent can create, deploy and read them for you.
