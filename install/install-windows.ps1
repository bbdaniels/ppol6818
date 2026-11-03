# PPOL 6818 course installer for Windows. Paste this one line into PowerShell:
#
#   powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-windows.ps1 | iex"
#
# It installs R, RStudio, Git, the GitHub command-line tool, uv, Codex and
# OpenCode with winget, installs the course R package, creates the course
# folder, and opens it in RStudio, where course setup continues.
# It is safe to run again: anything already installed is kept.

$ErrorActionPreference = "Stop"
trap { if ($env:PPOL6818_CHILD -eq "1") { Write-Host $_ -ForegroundColor Red; Read-Host "Press Enter to close this window" }; break }
function Say($m) { Write-Host "`n$m" -ForegroundColor Cyan }
# Failures in the elevated window wait for Enter, so the message can be read.
function Fail($m) {
  Write-Host $m -ForegroundColor Red
  if ($env:PPOL6818_CHILD -eq "1") { Read-Host "Press Enter to close this window" }
  exit 1
}
function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path", "User")
}

$url = "https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-windows.ps1"
$projectFile = Join-Path $env:TEMP "ppol6818-project.txt"
$elevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator)

Say "PPOL 6818 course installer"

# Ask Windows once: rerun this installer in one elevated window, wait for it,
# then open RStudio here, unelevated, so course setup runs as the student.
if (-not $elevated) {
  # S-1-5-32-544 is the Administrators group in every language of Windows;
  # an administrator's unelevated session still lists it.
  if (-not ((whoami /groups) -match "S-1-5-32-544")) {
    Write-Host "This Windows account is not an administrator, so it cannot install programs."
    Write-Host "Sign in to an administrator account and run this line again."
    exit 1
  }
  Remove-Item $projectFile -ErrorAction SilentlyContinue
  Write-Host "Click Yes when Windows asks to allow changes. The installation runs in a second window."
  $cmd = "`$env:PPOL6818_CHILD='1'; irm $url | iex"
  try {
    Start-Process powershell -Verb RunAs -Wait -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command $cmd"
  } catch {
    Write-Host "Windows did not allow the installation. Run this line again and click Yes."
    exit 1
  }
  if (-not (Test-Path $projectFile)) {
    Write-Host "The installation did not finish. Run this line again; anything already installed is kept."
    exit 1
  }
  $project = Get-Content $projectFile
  Say "Done. RStudio is opening the course project; course setup continues there."
  Start-Process $project
  exit 0
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Fail "winget is missing. Install 'App Installer' from the Microsoft Store, then run this again."
}

$packages = [ordered]@{
  "RProject.R"   = "R"
  "Posit.RStudio" = "RStudio"
  "Git.Git"      = "Git"
  "GitHub.cli"   = "GitHub CLI"
  "astral-sh.uv" = "uv"
  "OpenAI.Codex" = "Codex"
}
foreach ($id in $packages.Keys) {
  $listed = winget list --id $id -e --accept-source-agreements 2>$null | Select-String -SimpleMatch $id
  if ($listed) { Write-Host "$($packages[$id]) is already installed."; continue }
  Say "Installing $($packages[$id])"
  winget install --id $id -e --silent --accept-source-agreements --accept-package-agreements
}
Refresh-Path

# OpenCode 2 ships its installer as a shell script; Git for Windows provides the shell.
$opencode = Join-Path $HOME ".opencode\bin\opencode.exe"
if (Test-Path $opencode) {
  Write-Host "OpenCode is already installed."
} else {
  Say "Installing OpenCode"
  & "C:\Program Files\Git\bin\bash.exe" -lc "curl -fsSL https://opencode.ai/v2/install | bash"
}
$ocBin = Join-Path $HOME ".opencode\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$ocBin*") { [Environment]::SetEnvironmentVariable("Path", "$userPath;$ocBin", "User") }
Refresh-Path

$rscript = Get-ChildItem "C:\Program Files\R\R-*\bin\Rscript.exe" | Sort-Object FullName | Select-Object -Last 1
if (-not $rscript) { Fail "R did not install. Run this installer again." }

Say "Installing the course R package (a few minutes the first time)"
# Windows PowerShell drops double quotes inside arguments to programs, so the
# R code goes through a file rather than Rscript -e.
$rfile = Join-Path $env:TEMP "ppol6818-install.R"
@'
options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
pak::pak("bbdaniels/ppol6818", ask = FALSE)
cat(ppol6818::make_course_project(), file = file.path(Sys.getenv("TEMP"), "ppol6818-project.txt.part"))
'@ | Set-Content -Path $rfile -Encoding ASCII
& $rscript.FullName $rfile
if ($LASTEXITCODE -ne 0) { Fail "The course R package did not install. Run this installer again." }
Move-Item -Force "$projectFile.part" $projectFile
$project = Get-Content $projectFile

# In the elevated window, hand back to the first window, which opens RStudio
# unelevated. Run directly from an elevated PowerShell (or in a test), open it here.
if ($env:PPOL6818_CHILD -eq "1") { Say "Installation finished. This window closes in a few seconds."; Start-Sleep 3; exit 0 }
if ($env:CI) { Write-Host "Course project: $project"; exit 0 }
Say "Done. RStudio is opening the course project; course setup continues there."
Start-Process $project
