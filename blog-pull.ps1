# blog-pull.ps1
$ErrorActionPreference = "Stop"

Write-Host "[1/3] Checking current git status..." -ForegroundColor Cyan
git status --short

Write-Host "[2/3] Pulling latest changes..." -ForegroundColor Cyan
git pull --ff-only

Write-Host "[3/3] Done." -ForegroundColor Green
Write-Host "You can now edit your blog in Obsidian." -ForegroundColor Yellow