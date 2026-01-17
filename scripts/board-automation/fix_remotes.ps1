# PowerShell Script to Fix Remotes & Push
# Actions:
# 1. Lead Scraper: Push current feature branch
# 2. Website: Ensure main is synced

Write-Host "--- Fixing Repositories ---"

# --- 1. Lead Scraper ---
$scraperPath = "..\..\Production\lead-scraper"
Write-Host "Processing Lead Scraper..."
if (Test-Path $scraperPath) {
    # Set Remote
    git -C $scraperPath remote set-url origin "https://github.com/Spore-Sec/lead-scraper.git"
    
    # Get Current Branch
    $branch = git -C $scraperPath rev-parse --abbrev-ref HEAD
    Write-Host "  Current Branch: $branch"
    
    # Push & Set Upstream
    Write-Host "  Pushing to origin/$branch..."
    git -C $scraperPath push -u origin $branch
} else {
    Write-Host "  ERROR: Path not found!"
}

# --- 2. Website ---
$webPath = "..\..\Production\website"
Write-Host "`nProcessing Website..."
if (Test-Path $webPath) {
    # Set Remote
    git -C $webPath remote set-url origin "https://github.com/Spore-Sec/website.git"
    
    # Get Current Branch
    $branch = git -C $webPath rev-parse --abbrev-ref HEAD
    Write-Host "  Current Branch: $branch"
    
    # Push & Set Upstream
    Write-Host "  Pushing to origin/$branch..."
    git -C $webPath push -u origin $branch
} else {
    Write-Host "  ERROR: Path not found!"
}

Write-Host "`n---------------------------------------------------"
Write-Host "Fix Complete. Try pushing from VS Code now."
Write-Host "---------------------------------------------------"
