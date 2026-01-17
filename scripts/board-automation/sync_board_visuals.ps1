# PowerShell Script to Sync Project Visuals
# 1. Syncs Labels -> Project Fields (Component, Priority)
# 2. Auto-Assigns Users (AngelRattner, Mahdy-gribkov)

$org = "Spore-Sec"
$projectNumber = 2
$assignees = @("AngelRattner", "Mahdy-gribkov", "SporeSec")

Write-Host "--- Syncing Project Visuals ---"

# 1. Load Fields
$fieldsJson = Get-Content "fields.json" -Raw | ConvertFrom-Json
$compField = $fieldsJson.fields | Where-Object { $_.name -eq "Component" }
$prioField = $fieldsJson.fields | Where-Object { $_.name -eq "Priority" }

if (-not $compField) { Write-Host "Checking for 'Component' field... Not found in JSON? Trying by name..." }

# 2. Get Items
Write-Host "Fetching Items..."
$items = gh project item-list $projectNumber --owner $org --format json --limit 100 | ConvertFrom-Json

foreach ($item in $items.items) {
    $title = $item.content.title
    $labels = $item.content.labels
    $itemId = $item.id
    
    Write-Host "Processing: $title"

    # --- A. Sync Component ---
    $compVal = ""
    if ($labels -contains "component:scraper") { $compVal = "Scraper" }
    elseif ($labels -contains "component:website") { $compVal = "Website" }
    elseif ($labels -contains "component:backend") { $compVal = "Backend" }

    if ($compVal -ne "") {
        Write-Host "  -> Setting Component: $compVal"
        # Try Text Field Update
        try {
            gh project item-edit --id $itemId --field-id $compField.id --text "$compVal"
        } catch {
             # Fallback if field object missing locally, try by name
             gh project item-edit --id $itemId --field-id "Component" --text "$compVal"
        }
    }

    # --- B. Sync Priority ---
    # (Simplified: Just log for now, Mapping Select options is brittle without exact IDs)

    # --- C. Assign Users ---
    # Issue ID is needed, not Project Item ID. 
    # $item.content.url gives https://github.com/Spore-Sec/repo/issues/123
    if ($item.content.type -eq "Issue") {
        $issueUrl = $item.content.url
        Write-Host "  -> Assigning Founders..."
        try {
            foreach ($u in $assignees) {
                gh issue edit $issueUrl --add-assignee $u
            }
        } catch {
            Write-Host "    Failed to assign: $_"
        }
    }
}

Write-Host "Sync Complete."
