# Working with GitHub in VS Code

Every assignment in this course lives in a GitHub repository: a folder of files whose history GitHub keeps. You work on it in your codespace, save your steps as commits, and push them to GitHub, where the teaching team and your partner see them. This page covers everything you do with GitHub this term. You need the setup guide finished first.

## Your repositories

- **Every week:** `lab-<your GitHub username>`, yours alone, for your labs. Each week's lab is a folder in it, `week-01`, `week-02` and so on; the course adds the week's starter files before class.
- **From week 2:** `project-pairNN` (for example `project-pair04`), shared with your partner, for your pair's project: your code, your landing page, your slide deck and your two papers.

Both are private: only you, your partner and the teaching team can see them. The one public part is your pair's minisite, built from the `docs` folder (below).

Both open in your one codespace, side by side in the file list on the left. A new repository arrives by itself: each time the R console starts (when you open the codespace), the course accepts any course invitation and downloads new course repositories into the codespace. If one does not appear, click **Course setup** in the PPOL 6818 section.

## Every time you work

VS Code's **Source Control** view (the branch icon in the left sidebar, or Ctrl+Shift+G) lists each repository with its own changes, so check the repository's name before you commit.

1. **Pull first.** In Source Control, click the **...** beside the repository's name and choose **Pull**. It brings in whatever your partner pushed since you last worked.
2. **Work.** Write, run and check code with the agent; write your own text.
3. **Commit each step that works.** In Source Control, under the repository's name, click **+** beside each file you changed to stage it, type a short message that says what changed ("Add the 2014 to 2019 ACS extract") in the box above, and click **Commit**.
4. **Push.** Click **Sync Changes**. It pulls your partner's new commits and pushes yours. Your commits are now on GitHub.

A commit stays in your codespace until you push it. Nothing counts as submitted until it is pushed.

You can also ask the agent to do steps 3 and 4 ("commit the week 2 files and push"). Check Source Control afterwards: the repository should show no changes and no commits waiting to sync.

## Working with your partner

You share one repository. Pull before you start, and push when you stop. Small, frequent commits make it rare that you both change the same lines.

- **Push refused** ("Updates were rejected"): your partner pushed first. Click **Sync Changes** again, which pulls first.
- **Pull reports a conflict:** you both changed the same lines of one file. VS Code marks the file with a **!** in Source Control and shows both versions in it, with **Accept Current Change** and **Accept Incoming Change** above each. You and your partner decide which text stays, save, stage the file, commit and push. Ask the agent to help if you are unsure.
- Agree who edits which file when you work at the same time, above all `index.qmd` and `deck.qmd`.

## What never goes into a repository

Data. Your IPUMS extract and anything downloaded or derived from it stay in the `data` folder, which Git ignores, so it never appears in Source Control. If a data file does appear there (a `.csv` you saved elsewhere, for example), do not stage it: ask the agent to move it into `data` or add it to `.gitignore`. Keys never go into a repository either; setup keeps them outside it.

## Your minisite

From week 2 your pair publishes a minisite: a landing page (`index.qmd`), which grows into your pre-analysis plan, a slide deck (`deck.qmd`, built as a PDF) with one new slide each week, and a page for each of your two papers. Every sentence on them is your own; the agent writes the code that makes the figures and tables, which it saves into the `exhibits` folder. Only aggregate tables and figures go in `exhibits`, never rows of data, because the minisite is public. To see a figure, click it in the file list.

To publish it:

1. Click **Build minisite** in the PPOL 6818 section. It first pulls your partner's latest pushed work, then builds the site into the `docs` folder, and stops if a figure or table the pages show is missing. Click `docs/deck.pdf` in the file list to check the deck.
2. Commit everything in `docs` (click **+** beside the `docs` folder to stage it all), and push.
3. A few minutes later the site is live at `https://ppol-6818-2027.github.io/project-pairNN/`, with your pair's number. Open it in a private browser window and check that your changes are there; if not, wait a minute and reload. What that window shows is what the teaching team sees.

## Finding your links

- **Repository:** `https://github.com/ppol-6818-2027/project-pairNN`, and your labs at `https://github.com/ppol-6818-2027/lab-<your GitHub username>`. Open it to check that your latest commit arrived: its message and time show at the top of the file list.
- **Minisite:** `https://ppol-6818-2027.github.io/project-pairNN/`.

## Submitting

At each deadline a script records your repository's latest pushed commit as your submission; commits after the deadline count toward the next week. Push before the deadline, then submit the link each week's Canvas assignment asks for: the assignment gives the steps for that week, and "How to submit" in the course rules gives them for every week.

## When something goes wrong

- **A repository is missing from the file list:** click **Course setup** in the PPOL 6818 section; it accepts invitations and downloads new repositories.
- **Push asks for a password or is refused for permission:** click **Check** in the PPOL 6818 section; if the GitHub line fails, click **Course setup**.
- **The minisite shows an old version:** check that `docs` was committed and pushed, then wait a minute and reload.
- Anything else: ask the agent first, and bring it to office hours if that does not fix it.
