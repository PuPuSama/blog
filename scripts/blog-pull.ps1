$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
Set-Location $repoRoot

Write-Host "[1/4] Using repo: $repoRoot" -ForegroundColor Cyan

Write-Host "[2/4] Checking current git status..." -ForegroundColor Cyan
git status --short

$hasChanges = (git status --porcelain)
if (-not [string]::IsNullOrWhiteSpace($hasChanges)) {
    Write-Host "[3/4] Working tree is not clean. Pull may fail or create confusion." -ForegroundColor Yellow
    Write-Host "Commit/stash/discard local changes before pulling if needed." -ForegroundColor Yellow
} else {
    Write-Host "[3/4] Working tree is clean." -ForegroundColor Green
}

Write-Host "[4/4] Pulling latest changes..." -ForegroundColor Cyan
git pull --ff-only

Write-Host "Done." -ForegroundColor Green
Write-Host "You can now edit your blog in Obsidian." -ForegroundColor Yellow
