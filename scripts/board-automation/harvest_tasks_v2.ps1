# PowerShell Harvester V2 (Clean Rewrite)
$org = "Spore-Sec"
$repo = "lead-scraper"
$basePath = "..\..\Production\lead-scraper"

Write-Host "--- Starting Harvester V2 ---"

function Add-Task {
    param ($t, $b, $l)
    $exists = gh issue list --repo "$org/$repo" --search "$t in:title" --json title
    if ($exists -eq "[]") {
        Write-Host "Creating: $t"
        gh issue create --repo "$org/$repo" --title "$t" --body "$b" --label "$l" --project "SporeSec Platform"
    } else {
        Write-Host "Skipping: $t (Exists)"
    }
}

# 1. TODO.md
$todo = Join-Path $basePath "docs/TODO.md"
if (Test-Path $todo) {
    Write-Host "Reading TODO.md..."
    Get-Content $todo | ForEach-Object {
        if ($_ -match "^- \[ \] (.*)") {
            Add-Task "Docs: $($matches[1])" "From TODO.md" "component:scraper,type:feature,size:S"
        }
    }
}

# 2. Code Comments
Write-Host "Scanning Code..."
$files = Get-ChildItem -Path $basePath -Recurse -Include "*.go", "*.js"
if ($files) {
    foreach ($f in $files) {
        $lines = Get-Content $f.FullName
        $i = 0
        foreach ($line in $lines) {
            $i++
            if ($line -match "// TODO: (.*)") {
                $txt = $matches[1].Trim()
                $rel = $f.FullName
                Add-Task "Tech Debt: $txt" "File: $rel Line: $i" "component:scraper,type:tech-debt,size:S"
            }
        }
    }
}

Write-Host "Harvest Complete."
