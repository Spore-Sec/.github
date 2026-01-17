# PowerShell Script to Enforce Assignment Logic (The "Split")
# Logic:
# 1. Tech Debt / Scraper Tasks -> Assigned to Co-Founders (Angel/Mahdy). REMOVE SporeSec.
# 2. Logic: If no specific agent label, assume Human.
# 3. Future AI Tasks -> Will be assigned SporeSec.

$org = "Spore-Sec"
$projectNumber = 2
$humanTeam = @("AngelRattner", "Mahdy-gribkov")
$botUser = "SporeSec"

Write-Host "--- Enforcing Assignment Logic ---"

$items = gh project item-list $projectNumber --owner $org --format json --limit 100 | ConvertFrom-Json

foreach ($item in $items.items) {
    if ($item.content.type -ne "Issue") { continue }
    
    $title = $item.content.title
    $labels = $item.content.labels
    $assignees = $item.content.assignees
    $url = $item.content.url
    
    Write-Host "Processing: $title"
    
    # Logic: These harvested tasks (Tech Debt, Docs) are for HUMANS to review/prioritize first.
    # We strip SporeSec from them to clean the "Agent Queue".
    
    if ($assignees -contains $botUser) {
        Write-Host "  -> Removing @SporeSec (This is a Human/Backlog task)"
        gh issue edit $url --remove-assignee $botUser
    }
    
    # Ensure Humans are assigned
    foreach ($human in $humanTeam) {
        if ($assignees -notcontains $human) {
            Write-Host "  -> Adding $human"
            gh issue edit $url --add-assignee $human
        }
    }
    
    # Ensure Milestone (Phase 2: Platform Alpha) for these tech debt items
    # (Simplified: applying to all current backlog items)
    Write-Host "  -> Setting Milestone: Phase 2"
    gh issue edit $url --milestone "Phase 2: Platform Alpha"
}

Write-Host "Assignment Cleanup Complete."
