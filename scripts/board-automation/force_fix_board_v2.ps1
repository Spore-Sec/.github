# PowerShell Script to FORCE FIX Board (Safe Quoting)
$org = "Spore-Sec"
$projectId = "PVT_kwDODsl_8M4BMzFe" # Pre-validated Project ID

Write-Host "--- 1. Fetching Views ---"
Set-Content "get_views.graphql" 'query { organization(login: "Spore-Sec") { projectV2(number: 2) { views(first: 10) { nodes { id name } } } } }'
$views = gh api graphql -F query=@get_views.graphql | ConvertFrom-Json
$nodes = $views.data.organization.projectV2.views.nodes

Write-Host "Found $($nodes.Count) Views."

# Define Filters by Order
$filters = @(
    'priority:"P0","P1" status:Todo,"In Progress"', # View 0
    'assignee:@SporeSec',                            # View 1
    'component:scraper',                             # View 2
    'component:backend'                              # View 3
)

for ($i = 0; $i -lt $nodes.Count; $i++) {
    if ($i -ge $filters.Count) { break }
    
    $view = $nodes[$i]
    $filter = $filters[$i]
    
    Write-Host "Updating View Index $i (ID: $($view.id))"
    Write-Host "  -> Applying Filter: $filter"
    
    # Safe Filter String
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
    $file = "force_view_fix_$i.graphql"
    Set-Content $file $mutation
    gh api graphql -F query=@$file
}

Write-Host "`n--- 2. Cleaning Assignments (Re-Run) ---"
$items = gh project item-list 2 --owner $org --format json --limit 100 | ConvertFrom-Json
foreach ($item in $items.items) {
    if ($item.content.type -ne "Issue") { continue }
    
    $assignees = $item.content.assignees
    $labels = $item.content.labels
    $url = $item.content.url
    $title = $item.content.title
    
    if ($labels -contains "agent:ai") {
        if ($assignees -contains "Mahdy-gribkov" -or $assignees -contains "AngelRattner") {
            try {
                gh issue edit $url --remove-assignee "Mahdy-gribkov,AngelRattner"
            } catch {}
        }
    } else {
        if ($assignees -contains "SporeSec") {
            try {
                gh issue edit $url --remove-assignee "SporeSec"
            } catch {}
        }
    }
}
Write-Host "Done."
