# PowerShell Script to Apply Filters & Export Backlog
# Actions:
# 1. Match View Name -> Apply Filter
# 2. Export current backlog for Claude

$org = "Spore-Sec"
$projectId = "PVT_kwDODsl_8M4BMzFe" # From previous output (Project 2)

# Define Logic
$configMap = @{
    "🦅 Cockpit"        = 'priority:"P0","P1" status:Todo,"In Progress"'
    "🤖 Agent Queue"    = 'assignee:@SporeSec status:Todo,Ready'
    "🕸️ Scraper Squad"  = 'component:scraper'
    "🧠 Backend Core"   = 'component:backend'
}

Write-Host "--- Applying Filters ---"
$views = Get-Content unique_views_map.json | ConvertFrom-Json
$nodes = $views.data.organization.projectV2.views.nodes

foreach ($view in $nodes) {
    if ($configMap.ContainsKey($view.name)) {
        $filter = $configMap[$view.name]
        Write-Host "Updating '$($view.name)' with Filter: '$filter'"
        
        # Safe Filter String
        $safeFilter = $filter.Replace('"', '\"')
        
        $mutation = @"
mutation {
  updateProjectV2View(input: {
    projectId: "$projectId"
    viewId: "$($view.id)"
    filter: "$safeFilter"
  }) {
    view {
      id
      filter
    }
  }
}
"@
        $mutFile = "fix_filter_$($view.id).graphql"
        Set-Content -Path $mutFile -Value $mutation
        gh api graphql -F query=@$mutFile
    }
}

Write-Host "--- Exporting Backlog for AI ---"
# Export only Title and Body to keep it clean for Claude
gh project item-list 2 --owner Spore-Sec --format json --limit 100 > current_backlog.json

Write-Host "Done."
