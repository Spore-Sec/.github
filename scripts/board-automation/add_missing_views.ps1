# PowerShell Script to Aadd Missing Views (5 & 6)
# Actions:
# 1. Create "📅 Roadmap" (Milestones)
# 2. Create "🚦 Status Board" (Status)

$projectId = "PVT_kwDODsl_8M4BMzFe" # Project 2

function Create-View {
    param ($name, $filter)
    Write-Host "Creating View: $name"
    
    $mutation = @"
mutation {
  createProjectV2View(input: {
    projectId: "$projectId"
    name: "$name"
  }) {
    view {
      id
    }
  }
}
"@
    $file = "create_view.graphql"
    Set-Content $file $mutation
    # Create the view
    $json = gh api graphql -F query=@$file | ConvertFrom-Json
    $newId = $json.data.createProjectV2View.view.id
    
    # Update filter
    if ($newId) {
        Write-Host "  -> Created ($newId). Setting Filter..."
        $safeFilter = $filter.Replace('"', '\"')
        $updateMut = @"
mutation {
  updateProjectV2View(input: {
    projectId: "$projectId"
    viewId: "$newId"
    filter: "$safeFilter"
  }) {
    view { id }
  }
}
"@
        Set-Content "update_view.graphql" $updateMut
        gh api graphql -F query=@update_view.graphql
    }
}

Write-Host "--- Adding Missing Views ---"

# View 5: Milestones
Create-View "📅 Roadmap" 'no:milestone' # Filter shows items with NO milestone? Or just all? letting empty for now or specific logic? 
# Actually user wants "Milestone View". Usually implies Grouping. 
# API can't set Grouping easily. We will create the container.
Create-View "📅 Roadmap" ""

# View 6: Status
Create-View "🚦 Status Board" ""

Write-Host "Done."
