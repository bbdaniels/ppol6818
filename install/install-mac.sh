#!/bin/bash
# PPOL 6818 course installer for Mac. Paste this one line into Terminal:
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-mac.sh)"
#
# It installs R, RStudio, Git, the GitHub command-line tool, uv, Codex and
# OpenCode, installs the course R package, creates the course folder
# ~/Projects/ppol-6818, and opens it in RStudio, where course setup continues.
# It is safe to run again: anything already installed is kept.

set -euo pipefail

say() { printf '\n\033[1m%s\033[0m\n' "$1"; }
have_app() { [ -d "/Applications/$1.app" ]; }

say "PPOL 6818 course installer"
echo "Your Mac password may be requested once (it does not show as you type)."

if ! command -v brew >/dev/null 2>&1; then
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && eval "$("$b" shellenv)" && break
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  say "Installing Homebrew (the Mac installer for the other programs)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && eval "$("$b" shellenv)" && break
  done
  grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null || echo "eval \"\$($(command -v brew) shellenv)\"" >> "$HOME/.zprofile"
fi

say "Installing command-line tools: Git, GitHub CLI, uv, OpenCode"
brew install git gh uv opencode

if [ -d /Library/Frameworks/R.framework ] || command -v R >/dev/null 2>&1; then
  echo "R is already installed."
else
  say "Installing R"
  brew install --cask r-app
fi

if have_app RStudio; then
  echo "RStudio is already installed."
else
  say "Installing RStudio"
  brew install --cask rstudio
fi

if command -v codex >/dev/null 2>&1; then
  echo "Codex is already installed."
else
  say "Installing Codex"
  brew install --cask codex
fi

RSCRIPT="$(command -v Rscript || echo /Library/Frameworks/R.framework/Resources/bin/Rscript)"
say "Installing the course R package (a few minutes the first time)"
"$RSCRIPT" -e 'options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
pak::pak("bbdaniels/ppol6818", ask = FALSE)'
PROJECT="$("$RSCRIPT" -e 'cat(ppol6818::make_course_project())')"

say "Done. RStudio is opening the course project; course setup continues there."
open -a RStudio "$PROJECT"
