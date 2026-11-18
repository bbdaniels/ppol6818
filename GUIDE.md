# PPOL 6818 setup guide

You will do all of your coding for this course in RStudio, in the browser, with an AI coding agent beside you in RStudio's Terminal. RStudio runs in a GitHub codespace: a computer GitHub runs for you, with R, RStudio, the agent and the course tools already installed, and the course's IPUMS and KoboToolbox accounts reach it by themselves. Nothing goes on your own computer, and any computer with a current browser works. (To keep RStudio and the agent on your own computer after the course, see [RStudio on your own computer](computer.md); it is optional and not part of setup.)

Setup has four steps and takes about half an hour, spread over a few days because of the invitation in step 3. Submit your GitHub username by Sunday, January 10, 2027, and your setup check by Sunday, January 17.

## 1. Create two accounts

Use your personal email address for each one, so that you keep the accounts after you leave Georgetown.

- **GitHub** (https://github.com/signup). Then add your Georgetown email to your GitHub account as a second address (https://github.com/settings/emails) and apply for GitHub Education (https://github.com/settings/education/benefits) with it; approval can take a few days, and nothing waits for it.
- **An AI agent subscription**, required from the first class: either ChatGPT Plus ($20 a month, https://chatgpt.com/pricing), which runs Codex, or Claude Pro ($20 a month, https://claude.com/pricing), which runs Claude Code. Either one is the course's AI coding agent; you need only one. If you choose ChatGPT, also claim Codex for Students (https://chatgpt.com/codex/students) on the same account with your Georgetown email: it adds extra Codex usage for when you reach Plus's limits.

You do not need an IPUMS or KoboToolbox account: the course has one of each, and its keys reach your codespace by themselves.

## 2. Submit your GitHub username

Submit your GitHub username in the **GitHub username** assignment on Canvas: just the username, such as `jsmith`, not the address of your profile. We use it to invite you to the course organization on GitHub and to make your lab repository, `lab-<your username>`, the repository that holds all your labs this term.

## 3. Accept the invitation

Within a few days GitHub emails you an invitation to the course organization, `ppol-6818-2027`. Accept it, or accept it at https://github.com/orgs/ppol-6818-2027/invitation while signed in to GitHub.

## 4. Open RStudio and finish setup

Open your lab repository at `https://github.com/ppol-6818-2027/lab-<your username>`. Click the green **Code** button, the **Codespaces** tab, and **Create codespace on main**.

GitHub then asks to give this codespace access to the other repositories in `ppol-6818-2027`. Click **Authorize and continue**: that is how your pair's project repository opens beside your lab repository later in the term. If you skipped it, delete the codespace at https://github.com/codespaces and create it again.

A code editor opens in the browser; if it asks whether you trust the folder's authors, click **Trust Folder & Continue**. After about a minute RStudio opens in a new browser tab, on your lab repository. If your browser blocks the new tab, click **Ports** at the bottom of the editor and then the globe beside **RStudio**.

RStudio then walks you through the one sign-in it needs: it asks which subscription you have, ChatGPT Plus or Claude Pro, and signs you in to that agent in RStudio's Terminal (it shows a link and a code; open the link, sign in, and enter the code). You are already signed in to GitHub. At the end it prints a check like this one:

```
PPOL 6818 setup check
  Programs installed                 PASS  git, gh, codex, claude
  Course folder                      PASS  codespace your-codespace-name
  GitHub sign-in                     PASS  your-username
  AI agent sign-in                   PASS  Codex signed in
  KoboToolbox key                    PASS  ppol6818
  IPUMS key                          PASS  key works
  Agent connected to RStudio         PASS  rstudio connector set up in Codex
  Course organization                PASS  lab-your-username (no pair repository yet)
  Course data                        PASS  0.0 B of data
```

Copy the whole check into the **Setup check** assignment on Canvas. If any line says FAIL, click **Addins > Course setup** in RStudio's toolbar to try that step again, and bring the check to Sifat's lab session or office hours if it fails again. To print the check again at any time, run `ppol6818::check()` in RStudio's Console.

## Coming back

Click **Open RStudio** on the Canvas home page. It opens https://github.com/codespaces, the list of your codespaces; click yours and RStudio opens again where you left it. Keep this one codespace all term: when pairs are formed, your pair's project repository appears beside your lab repository in it (switch between them in RStudio's **Projects** menu, top right).

The codespace stops by itself after 30 idle minutes and keeps your files. GitHub deletes a codespace after 30 days unused, so push your work to GitHub before you leave it. GitHub's free allowance covers about 60 hours a month in the course codespace, and about 90 with GitHub Education, and its storage allowance (15 GB a month, or 20 with GitHub Education) holds one course codespace: do not create a second one, and delete any old one at https://github.com/codespaces.

## Working with the agent

The course agent, Codex or Claude Code, opens in RStudio's Terminal every time RStudio opens a course project. If you close it, click **Addins > Course agent** to open it again, in the project you have open. It uses the account you signed in with during setup. Ask it in plain English to write, run and check code. It runs its code in RStudio's Console, as if you had pressed Run: you see the code and what it prints in the Console, the objects it makes in the Environment pane and its plots in the Plots pane. The agent reads the course rules from the file `AGENTS.md` in each repository (Claude Code reaches it through `CLAUDE.md`): it writes code and shows you evidence that it worked, and it does not write the prose you submit.

## Data

Your course repositories are private; only the minisite you publish from your pair's repository is public. IPUMS data never goes into a repository, because the IPUMS terms do not allow sharing it: each lab's code downloads the extract through the course's IPUMS account into a `data` folder that Git ignores. Your pair's KoboToolbox forms live in the course's KoboToolbox account, and the agent can create, deploy and read them for you.
