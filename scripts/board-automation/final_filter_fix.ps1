# PowerShell Script to Apply Final Filters (Strict Mode)
# Target: Existing Views (ID-based)

$org = "Spore-Sec"
$projectId = "PVT_kwDODsl_8M4BMzFe" # Verified Project ID

# Mapping from previous JSON output (manual extraction for safety)
# View 0 (Roadmap): PVTV_lADODsl_8M4BMzFezgJDj7w
# View 1 (Agent Queue): PVTV_lADODsl_8M4BMzFezgJDk8o
# ... (Wait, logic relies on Order mostly, assuming user renamed 1->Roadmap, 2->Agent)

$views = Get-Content final_view_state.json | ConvertFrom-Json
$nodes = $views.data.organization.projectV2.views.nodes

Write-Host "--- Applying Final Strict Filters ---"

# Map by NAME (Since user renamed them manually, we can trust the Name now!)
$configMap = @{
    "Roadmap"           = 'priority:"P0","P1"'
    "Agent Queue"       = 'assignee:@SporeSec label:agent:ai' # Strict AND
    "Scraper Squad"     = 'component:scraper'
    "Backend Core"      = 'component:backend'
    "🦅 Cockpit"        = 'priority:"P0","P1"' # Fallback if user kept emoji
    "🤖 Agent Queue"    = 'assignee:@SporeSec label:agent:ai'
}

foreach ($view in $nodes) {
    # Check if Name matches any key
    foreach ($key in $configMap.Keys) {
        if ($view.name -eq $key) {
             Write-Host "Match! Updating '$($view.name)' ($($view.id))"
             $filter = $configMap[$key]
             Write-Host "  -> Filter: $filter"
             
             $safeFilter = $filter.Replace('"', '\"')
             
             $mutation = @"
mutation {
  updateProjectV2View(input: {
    projectId: "$projectId"
    viewId: "$($view.id)"
    filter: "$safeFilter"
  }) {
    view { id filter }
  }
}
"@
             $file = "strict_filter_$($view.id).graphql"
             Set-Content $file $mutation
             gh api graphql -F query=@$file
        }
    }
}

Write-Host "Final Fix Complete."
