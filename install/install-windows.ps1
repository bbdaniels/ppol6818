# PPOL 6818 course installer for Windows. Paste this one line into PowerShell:
#
#   powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/bbdaniels/ppol6818/main/install/install-windows.ps1 | iex"
#
# It installs R, RStudio, Git, the GitHub command-line tool, uv, Codex and
# OpenCode with winget, installs the course R package, creates the course
# folder, and opens it in RStudio, where course setup continues.
# It is safe to run again: anything already installed is kept.

$ErrorActionPreference = "Stop"
function Say($m) { Write-Host "`n$m" -ForegroundColor Cyan }
function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path", "User")
}

Say "PPOL 6818 course installer"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "winget is missing. Install 'App Installer' from the Microsoft Store, then run this again."
  exit 1
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
if (-not $rscript) { Write-Host "R did not install. Run this installer again."; exit 1 }

Say "Installing the course R package (a few minutes the first time)"
# Windows PowerShell drops double quotes inside arguments to programs, so the
# R code goes through a file rather than Rscript -e.
$rfile = Join-Path $env:TEMP "ppol6818-install.R"
@'
options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
pak::pak("bbdaniels/ppol6818", ask = FALSE)
cat(ppol6818::make_course_project(), file = file.path(Sys.getenv("TEMP"), "ppol6818-project.txt"))
'@ | Set-Content -Path $rfile -Encoding ASCII
& $rscript.FullName $rfile
if ($LASTEXITCODE -ne 0) { Write-Host "The course R package did not install. Run this installer again."; exit 1 }
$project = Get-Content (Join-Path $env:TEMP "ppol6818-project.txt")

Say "Done. RStudio is opening the course project; course setup continues there."
Start-Process $project
