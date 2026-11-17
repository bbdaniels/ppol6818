# Working with GitHub in RStudio

Every assignment in this course lives in a GitHub repository: a folder of files whose history GitHub keeps. You work on it in RStudio, save your steps as commits, and push them to GitHub, where the teaching team and your partner see them. This page covers everything you do with GitHub this term. You need the setup guide finished first.

## Your repositories

- **Week 1:** `pitch-<your GitHub username>`, yours alone, for your pitch slide.
- **From week 2:** `project-pairNN` (for example `project-pair04`), shared with your partner, for everything else: your code, your landing page and your slide deck.

Both are private: only you, your partner and the teaching team can see them. The one public part is your pair's minisite, built from the `docs` folder (below).

A new repository arrives the same way each time. Open the `ppol-6818` project in RStudio (**File > Recent Projects**); RStudio accepts the course invitation and downloads the repository into your `ppol-6818` folder. Then open the repository itself: **File > Open Project**, go to `ppol-6818`, the repository's folder, and choose `project.Rproj`. The course agent opens in the Terminal, and the **Git** pane (top right, beside Environment) shows the repository's changes.

## Every time you work

1. **Pull first.** Click **Pull** (the blue down arrow) in the Git pane. It brings in whatever your partner pushed since you last worked.
2. **Work.** Write, run and check code with the agent; write your own text in `index.qmd` and `deck.qmd`.
3. **Commit each step that works.** In the Git pane, tick the **Staged** box beside each file you changed, click **Commit**, write a short message that says what changed ("Add the 2014 to 2019 ACS extract"), and click **Commit** in that window.
4. **Push.** Click **Push** (the green up arrow). Your commits are now on GitHub.

A commit stays on your computer until you push it. Nothing counts as submitted until it is pushed.

You can also ask the agent to do steps 3 and 4 ("commit these changes and push"). Check the Git pane afterwards: it should be empty, with nothing left to commit.

## Working with your partner

You share one repository. Pull before you start, and push when you stop. Small, frequent commits make it rare that you both change the same lines.

- **Push refused** ("Updates were rejected"): your partner pushed first. Click **Pull**, then **Push** again.
- **Pull reports a conflict:** you both changed the same lines of one file. Ask the agent to help you resolve it. The file shows both versions between `<<<<<<<` and `>>>>>>>` lines; you and your partner decide which text stays, then commit and push.
- Agree who edits which file when you work at the same time, above all `index.qmd` and `deck.qmd`.

## What never goes into a repository

Data. Your IPUMS extract and anything downloaded or derived from it stay in the `data` folder, which Git ignores, so it never appears in the Git pane. If a data file does appear there (a `.csv` you saved elsewhere, for example), do not tick it: ask the agent to move it into `data` or add it to `.gitignore`. Keys never go into a repository either; setup keeps them outside it.

## Your minisite

From week 2 your pair publishes a minisite: a landing page (`index.qmd`), which grows into your pre-analysis plan, and a slide deck (`deck.qmd`), with one new slide each week. Every sentence on them is your own; the agent writes the code that makes the figures and tables, which it saves into the `exhibits` folder. Only aggregate tables and figures go in `exhibits`, never rows of data, because the minisite is public.

To publish it:

1. Click **Addins > Build minisite**. It builds the site into the `docs` folder and opens a preview.
2. Commit everything in `docs` (tick the whole folder), and push.
3. A few minutes later the site is live at `https://ppol-6818-2027.github.io/project-pairNN/`, with your pair's number. Open it in a private browser window and check that your changes are there; if not, wait a minute and reload. What that window shows is what the teaching team sees.

## Finding your links

- **Repository:** `https://github.com/ppol-6818-2027/project-pairNN` (in week 1, `https://github.com/ppol-6818-2027/pitch-<your GitHub username>`). Open it to check that your latest commit arrived: its message and time show at the top of the file list.
- **Minisite:** `https://ppol-6818-2027.github.io/project-pairNN/`; the deck is `deck.html` at the same address.

## Submitting

At each deadline a script records your repository's latest pushed commit as your submission; commits after the deadline count toward the next week. Push before the deadline, then submit the link each week's Canvas assignment asks for, once per pair: the assignment gives the steps for that week, and "How to submit" in the course rules gives them for every week.

## When something goes wrong

- **The Git pane is missing:** you opened the `ppol-6818` folder, not the repository. Open the repository's `project.Rproj`.
- **Push asks for a password:** run `ppol6818::check()` in the Console; if the GitHub line fails, click **Addins > Course setup**.
- **The minisite shows an old version:** check that `docs` was committed and pushed, then wait a minute and reload.
- Anything else: ask the agent first, and bring it to office hours if that does not fix it.
