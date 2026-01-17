# PowerShell Script to Configure Project Views (Renaming & Filtering)
# Actions:
# 1. Fetch current Views
# 2. Mutate them to match SporeSec Standard

$org = "Spore-Sec"
$projectNumber = 2

# Definition of Desired Views (Order matters if we just map sequentially)
# We will look for "View *" or just map the first 4 found.
$desiredViews = @(
    @{Name="🦅 Cockpit"; Filter='priority:"P0","P1"'},
    @{Name="🤖 Agent Queue"; Filter='assignee:@SporeSec status:Ready,Todo'},
    @{Name="🕸️ Scraper Squad"; Filter='component:scraper'},
    @{Name="🧠 Backend Core"; Filter='component:backend'}
)

Write-Host "--- Configuring Project Views ---"

# 1. Get Project ID and Views configuration
$queryFile = "query_views.graphql"
$viewData = gh api graphql -F query=@$queryFile | ConvertFrom-Json
$projectId = $viewData.data.organization.projectV2.id
$currentViews = $viewData.data.organization.projectV2.views.nodes

Write-Host "Found Project ID: $projectId"
Write-Host "Found $( $currentViews.Count ) Views."

# 2. Loop and Update
for ($i = 0; $i -lt $desiredViews.Count; $i++) {
    if ($i -ge $currentViews.Count) {
        Write-Host "Warning: More desired views than existing views. Skipping $($desiredViews[$i].Name)."
        continue
    }

    $targetView = $currentViews[$i]
    $config = $desiredViews[$i]
    
    Write-Host "Updating View '$($targetView.name)' ($($targetView.id)) -> '$($config.Name)'"
    
    # Construct Mutation
    # Note: escape double quotes in filter for the mutation string
    $safeFilter = $config.Filter.Replace('"', '\"')
    
    $mutation = @"
mutation {
  updateProjectV2View(input: {
    projectId: "$projectId"
    viewId: "$($targetView.id)"
    name: "$($config.Name)"
    filter: "$safeFilter"
  }) {
    view {
      id
      name
      filter
    }
  }
}
"@
    
    # Save Mutation to file to avoid quoting hell
    $mutFile = "mutate_view_$i.graphql"
    Set-Content -Path $mutFile -Value $mutation
    
    try {
        gh api graphql -F query=@$mutFile
        Write-Host "  -> Success"
    } catch {
        Write-Host "  -> Failed: $_"
    }
}

Write-Host "---------------------------------------------------"
Write-Host "View Configuration Complete!"
Write-Host "---------------------------------------------------"
