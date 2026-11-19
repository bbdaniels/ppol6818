# PPOL 6818 setup guide

You will do all of your coding for this course in VS Code, with an AI coding agent beside you. VS Code runs on your own computer, but your files, R and the agent run in a GitHub codespace: a computer GitHub runs for you, with R, the agent and the course tools already installed, and the course's IPUMS and KoboToolbox accounts reach it by themselves. The only things you install are VS Code and one extension for it. (To keep R and an agent on your own computer after the course, see [R on your own computer](computer.md); it is optional and not part of setup.)

Setup has five steps and takes about half an hour, spread over a few days because of the invitation in step 3. Submit your GitHub username by Sunday, January 10, 2027, and your setup check by Sunday, January 17.

## 1. Create two accounts

Use your personal email address for each one, so that you keep the accounts after you leave Georgetown.

- **GitHub** (https://github.com/signup). Then add your Georgetown email to your GitHub account as a second address (https://github.com/settings/emails) and apply for GitHub Education (https://github.com/settings/education/benefits) with it; approval can take a few days, and nothing waits for it. Your codespace runs on GitHub's free monthly allowance, which is more than the course needs, and GitHub Education raises it. Do not add a payment method to your GitHub account: without one, GitHub stops a codespace at the free allowance and never charges you. If your account already has one, set a $0 budget for Codespaces at https://github.com/settings/billing/budgets.
- **An AI agent subscription**, required from the first class: either Claude Pro ($20 a month, https://claude.com/pricing), which runs Claude Code, or ChatGPT Plus ($20 a month, https://chatgpt.com/pricing), which runs Codex. Either one is the course's AI coding agent; you need only one. If you choose ChatGPT, also claim Codex for Students (https://chatgpt.com/codex/students) on the same account with your Georgetown email: it adds extra Codex usage for when you reach Plus's limits.

You do not need an IPUMS or KoboToolbox account: the course has one of each, and its keys reach your codespace by themselves.

## 2. Submit your GitHub username

Submit your GitHub username in the **GitHub username** assignment on Canvas: just the username, such as `jsmith`, not the address of your profile. We use it to invite you to the course organization on GitHub and to make your lab repository, `lab-<your username>`, the repository that holds all your labs this term.

## 3. Install VS Code and accept the invitation

While you wait for the invitation:

1. Install VS Code from https://code.visualstudio.com (free, Mac or Windows) and open it once.
2. In VS Code, click **Extensions** in the left sidebar (four squares), search for **GitHub Codespaces**, and click **Install** on the one published by GitHub.
3. On GitHub, open https://github.com/settings/codespaces, set **Editor preference** to **Visual Studio Code**, and save. From now on every codespace opens in VS Code on your computer instead of in the browser.

Within a few days GitHub emails you an invitation to the course organization, `ppol-6818-2027`. Accept it, or accept it at https://github.com/orgs/ppol-6818-2027/invitation while signed in to GitHub.

## 4. Create your codespace

Once you have accepted the invitation, click **Launch codespace** on the Canvas home page. The first time, GitHub asks you to authorize **PPOL 6818 codespace link**, which only reads your username: click **Authorize**. GitHub then says "No codespace to resume": click **Create new codespace**. (If you click it before your lab repository is ready or before you have accepted the invitation, a page says what to do first.)

GitHub then asks to give this codespace access to the other repositories in `ppol-6818-2027`. Click **Authorize and continue**: that is how your pair's project repository opens beside your lab repository later in the term. If you skipped it, delete the codespace at https://github.com/codespaces and click **Launch codespace** again.

Your browser then asks to open VS Code: allow it. The first time, VS Code asks you to sign in to GitHub; click **Allow**, sign in in the browser, and come back. VS Code connects to the codespace. The first time takes about five minutes, while GitHub sets up the course software; after that it opens in seconds. When it asks "Do you trust the authors of the files in this folder?", click **Trust Folder & Continue**: the files are the course's and yours, and VS Code asks only once. It opens in three columns: your files on the left, `run.R` above the R console in the middle, and the agent on the right.

## 5. Sign in to your agent and finish setup

1. **Sign in to your agent** in the panel on the right. Claude Code is the first tab and Codex the second; use the one your subscription runs. Click its sign-in button, sign in in the browser with the account that holds your subscription, and come back to VS Code.
2. **Run course setup.** In the file list on the left, open the **PPOL 6818** section and click **Course setup**. It runs in the R console, finishes the steps the agent needs, and prints a check like this one:

```
PPOL 6818 setup check
  Programs installed                 PASS  git, gh, codex, claude
  Course folder                      PASS  codespace your-codespace-name
  GitHub sign-in                     PASS  your-username
  AI agent sign-in                   PASS  Claude Code signed in
  KoboToolbox key                    PASS  ppol6818
  IPUMS key                          PASS  key works
  Agent connected to R               PASS  R console connector set up in Claude Code
  Course organization                PASS  lab-your-username (no pair repository yet)
  Course data                        PASS  0.0 B of data
```

Copy the whole check into the **Setup check** assignment on Canvas. If any line says FAIL, click **Course setup** again, and bring the check to Sifat's lab session or office hours if it fails again. To print the check again at any time, click **Check** in the PPOL 6818 section, or run `ppol6818::check()` in the R console.

If the browser shows "localhost refused to connect" when you sign in to the agent, you are in VS Code in the browser rather than on your computer: go back to step 3, set the editor preference, and click **Launch codespace** on Canvas again.

## Coming back

Click **Launch codespace** on the Canvas home page: it opens your codespace in VS Code where you left it. (In VS Code itself, the **Remote Explorer** in the left sidebar lists it too.) Keep this one codespace all term: when pairs are formed, your pair's project repository appears beside your lab repository in it, in the same file list.

When you quit VS Code, the codespace stops by itself about half an hour later and keeps your files. GitHub deletes a codespace after 30 days unused, so push your work to GitHub before you leave it. GitHub's free allowance covers about 60 hours a month in the course codespace, and about 90 with GitHub Education, and its storage allowance (15 GB a month, or 20 with GitHub Education) holds one course codespace: do not create a second one, and delete any old one at https://github.com/codespaces.

## The window

- **Left: your files.** Both course repositories, your lab repository and later your pair's, are in one list. Click a file to open it: R scripts and Markdown open as text, figures (`.png`) as pictures and PDFs (your deck and papers) in a viewer. An open figure or PDF redraws by itself when your code saves it again. Below the files, the **PPOL 6818** section holds the course buttons: **Course setup**, **Build minisite** and **Check**.
- **Middle: the editor and the R console.** The R console is a terminal running R, in your lab repository. Select lines in a script and press Cmd+Enter (Ctrl+Enter on Windows) to run them there, or type in it directly.
- **Right: the agent.** Claude Code, with Codex as its second tab.

## Working with the agent

Ask the agent in plain English to write, run and check code. It runs its code in your R console, as if you had run it yourself: you see the code and what it prints in the console, and the objects it makes stay in your R session, where you can use them. Figures are saved to files, which you open by clicking them in the file list. The agent reads the course rules from the file `AGENTS.md` in each repository (Claude Code reaches it through `CLAUDE.md`): it writes code and shows you evidence that it worked, and it does not write the prose you submit.

## Data

Your course repositories are private; only the minisite you publish from your pair's repository is public. IPUMS data never goes into a repository, because the IPUMS terms do not allow sharing it: each lab's code downloads the extract through the course's IPUMS account into a `data` folder that Git ignores. Your pair's KoboToolbox forms live in the course's KoboToolbox account, and the agent can create, deploy and read them for you.
