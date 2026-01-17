# PowerShell Script to Sync v4.2.0 Plan (Strict Import)
$org = "Spore-Sec"
$repo = "lead-scraper"
$project = "SporeSec Platform"
$milestone = "Phase 2: Platform Alpha" # Equivalent to v4.2.0 for now

$completed = @(
    "Fix 3 scraper API handlers (routes.go)",
    "Update sidebar navigation (sidebar.templ)",
    "Add new page routes (/email-health, /notion-sync, /audit-log)",
    "Create Email Health page metrics & timeline",
    "Create Notion Sync page views & actions",
    "Create Audit Log page filtering",
    "Add page handlers (handlers_pages.go)",
    "Fix pipelineWidth helper bug"
)

$remaining = @(
    "Rebuild Lead Detail page with 6-tab navigation",
    "Enhance Outreach page with warmup timeline and rate gauges",
    "Expand email templates from 4 to 9 categories",
    "Implement exponential backoff retry logic in outreach.go"
)

Write-Host "--- Syncing v4.2.0 Plan ---"

# 1. Process Remaining Tasks (Priority P1)
foreach ($task in $remaining) {
    Write-Host "Creating TODO: $task"
    gh issue create --repo "$org/$repo" --title "$task" --body "Imported from v4.2.0 Plan" --label "component:scraper,priority:P1,type:feature,size:M" --project "$project" --milestone "$milestone" --assignee "Mahdy-gribkov"
}

# 2. Process Completed Tasks (History)
foreach ($task in $completed) {
    Write-Host "Creating DONE: $task"
    # Create and immediately close
    $url = gh issue create --repo "$org/$repo" --title "$task" --body "Completed in v4.2.0" --label "component:scraper,priority:P2,type:feature" --project "$project" --milestone "$milestone" --assignee "Mahdy-gribkov"
    gh issue close $url
}

Write-Host "Sync Complete."
