# blog-push.ps1
$ErrorActionPreference = "Stop"

Write-Host "[1/4] Checking git status..." -ForegroundColor Cyan
git status --short

$commitMessage = Read-Host "[2/4] Enter commit message"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    Write-Host "Commit message cannot be empty." -ForegroundColor Red
    exit 1
}

Write-Host "[3/4] Committing changes..." -ForegroundColor Cyan
git add .
git commit -m "$commitMessage"

Write-Host "[4/4] Pushing to remote..." -ForegroundColor Cyan
git push

Write-Host "Done. Your changes are now on GitHub." -ForegroundColor Green
Write-Host "Now go to the server and run:" -ForegroundColor Yellow
Write-Host "/root/.openclaw/workspace/publish-blog.sh"