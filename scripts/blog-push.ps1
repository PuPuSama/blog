$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
Set-Location $repoRoot

Write-Host "[1/5] Using repo: $repoRoot" -ForegroundColor Cyan

Write-Host "[2/5] Checking git status..." -ForegroundColor Cyan
git status --short

$commitMessage = Read-Host "[3/5] Enter commit message"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    Write-Host "Commit message cannot be empty." -ForegroundColor Red
    exit 1
}

Write-Host "[4/5] Staging and committing all changes..." -ForegroundColor Cyan
git add -A
git commit -m "$commitMessage"

Write-Host "[5/5] Pushing to remote..." -ForegroundColor Cyan
git push

Write-Host "Done. Your changes are now on GitHub." -ForegroundColor Green
Write-Host "Publish is a separate step on the server:" -ForegroundColor Yellow
Write-Host "/root/.openclaw/workspace/publish-blog.sh" -ForegroundColor Yellow
