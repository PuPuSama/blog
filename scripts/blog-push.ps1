$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
Set-Location $repoRoot

Write-Host "[1/6] Using repo: $repoRoot" -ForegroundColor Cyan

Write-Host "[2/6] Checking git status..." -ForegroundColor Cyan
git status --short

$pathsInput = Read-Host "[3/6] Enter file paths to stage (space-separated, relative to blog repo)"
if ([string]::IsNullOrWhiteSpace($pathsInput)) {
    Write-Host "No file paths provided. Abort." -ForegroundColor Red
    exit 1
}

$paths = $pathsInput -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
if ($paths.Count -eq 0) {
    Write-Host "No valid file paths provided. Abort." -ForegroundColor Red
    exit 1
}

Write-Host "Staging selected paths..." -ForegroundColor Cyan
git add -- @paths

$staged = (git diff --cached --name-only)
if ([string]::IsNullOrWhiteSpace($staged)) {
    Write-Host "Nothing is staged after git add. Abort." -ForegroundColor Red
    exit 1
}

Write-Host "Staged files:" -ForegroundColor Green
$staged

$commitMessage = Read-Host "[4/6] Enter commit message"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    Write-Host "Commit message cannot be empty." -ForegroundColor Red
    exit 1
}

Write-Host "[5/6] Committing changes..." -ForegroundColor Cyan
git commit -m "$commitMessage"

Write-Host "[6/6] Pushing to remote..." -ForegroundColor Cyan
git push

Write-Host "Done. Your changes are now on GitHub." -ForegroundColor Green
Write-Host "Publish is a separate step on the server:" -ForegroundColor Yellow
Write-Host "/root/.openclaw/workspace/publish-blog.sh" -ForegroundColor Yellow
