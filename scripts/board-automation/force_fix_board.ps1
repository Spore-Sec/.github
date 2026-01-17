# PowerShell Script to FORCE FIX Board
# 1. Apply Filters by INDEX (ignoring names)
# 2. Aggressive Assignment Cleanup

$org = "Spore-Sec"
$projectId = "PVT_kwDODsl_8M4BMzFe" # Project 2
$botUser = "SporeSec"

Write-Host "--- 1. Fetching Views ---"
$views = gh api graphql -F query='query { organization(login: "Spore-Sec") { projectV2(number: 2) { views(first: 10) { nodes { id name } } } } }' | ConvertFrom-Json
$nodes = $views.data.organization.projectV2.views.nodes

Write-Host "Found $($nodes.Count) Views."

# Define Filters by Order (0=Cockpit, 1=Agent, 2=Scraper, 3=Backend)
$filters = @(
    'priority:"P0","P1" status:Todo,"In Progress"', # View 0: Cockpit
    'assignee:@SporeSec',                            # View 1: Agent Queue
    'component:scraper',                             # View 2: Scraper Squad
    'component:backend'                              # View 3: Backend Core
)

for ($i = 0; $i -lt $nodes.Count; $i++) {
    if ($i -ge $filters.Count) { break }
    
    $view = $nodes[$i]
    $filter = $filters[$i]
    
    Write-Host "Updating View Index $i (ID: $($view.id))"
    Write-Host "  -> Applying Filter: $filter"
    
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
    $file = "force_view_$i.graphql"
    Set-Content $file $mutation
    gh api graphql -F query=@$file
}

Write-Host "`n--- 2. Cleaning Assignments ---"
$items = gh project item-list 2 --owner $org --format json --limit 100 | ConvertFrom-Json
foreach ($item in $items.items) {
    if ($item.content.type -ne "Issue") { continue }
    
    $assignees = $item.content.assignees
    $labels = $item.content.labels
    $url = $item.content.url
    $title = $item.content.title
    
    # Rule 1: AI Task (agent:ai) -> ONLY SporeSec
    if ($labels -contains "agent:ai") {
        if ($assignees -contains "Mahdy-gribkov" -or $assignees -contains "AngelRattner") {
            Write-Host "Cleaning AI Task: $title"
            gh issue edit $url --remove-assignee "Mahdy-gribkov,AngelRattner"
        }
    } 
    # Rule 2: Human Task (NOT agent:ai) -> REMOVE SporeSec
    else {
        if ($assignees -contains "SporeSec") {
            Write-Host "Cleaning Human Task: $title"
            gh issue edit $url --remove-assignee "SporeSec"
        }
    }
}

Write-Host "Force Fix Complete."
