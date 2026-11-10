#!/bin/bash
# PPOL 6818 course installer for Mac. Paste this one line into Terminal:
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-mac.sh)"
#
# It installs R, RStudio, Git, the GitHub command-line tool and Codex,
# installs the course R package, creates the course folder
# ~/Projects/ppol-6818, and opens it in RStudio, where course setup continues.
# It is safe to run again: anything already installed is kept.

set -euo pipefail

say() { printf '\n\033[1m%s\033[0m\n' "$1"; }
have_app() { [ -d "/Applications/$1.app" ]; }

say "PPOL 6818 course installer"

if ! /usr/sbin/dseditgroup -o checkmember -m "$USER" admin >/dev/null 2>&1; then
  echo "This Mac account is not an administrator, so it cannot install programs."
  echo "Sign in to an administrator account (System Settings, Users & Groups) and run this line again."
  exit 1
fi

# Ask for the password once, then keep sudo alive until the installer exits,
# so Homebrew and the R and RStudio installers never stop to ask again.
echo "Enter your Mac password (it does not show as you type), then press Return."
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &

if ! command -v brew >/dev/null 2>&1; then
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && eval "$("$b" shellenv)" && break
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  say "Installing Homebrew (the Mac installer for the other programs)"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && eval "$("$b" shellenv)" && break
  done
  grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null || echo "eval \"\$($(command -v brew) shellenv)\"" >> "$HOME/.zprofile"
fi

say "Installing command-line tools: Git, GitHub CLI"
brew install git gh

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

# RStudio and R come from the developers and are notarized; clearing the
# download flag skips macOS asking "Are you sure you want to open it?".
xattr -dr com.apple.quarantine /Applications/RStudio.app 2>/dev/null || true

RSCRIPT="$(command -v Rscript || echo /Library/Frameworks/R.framework/Resources/bin/Rscript)"
say "Installing the course R package (a few minutes the first time)"
"$RSCRIPT" -e 'options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
pak::pak("bbdaniels/ppol6818", ask = FALSE)'
PROJECT="$("$RSCRIPT" -e 'cat(ppol6818::make_course_project())')"

if [ -n "${CI:-}" ]; then echo "Course project: $PROJECT"; exit 0; fi
say "Done. RStudio is opening the course project; course setup continues there."
open -a RStudio "$PROJECT"
