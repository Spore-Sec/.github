# PowerShell Script: Sync Board V2 (Data Repair)
# Handles: Size/Effort (Labels -> Field) & Repository Metadata

$projectId = "PVT_kwDODsl_8M4BMzFe"
# IDs derived from prev step (Option 1: Hardcoded for robustness if parsing is brittle)
# Size Field ID: PVTSSF_lADODsl_8M4BMzFezg8AXkA
# Options: S (86949a6e), M (3745857e), L (c2040425), XL (f86248fc)

$sizeFieldId = "PVTSSF_lADODsl_8M4BMzFezg8AXkA"
$sizeMap = @{
    "size:S" = "86949a6e"
    "size:M" = "3745857e"
    "size:L" = "c2040425"
    "size:XL" = "f86248fc"
}

Write-Host "--- Starting Size & Repo Repair ---"

# We need to fetch items again to get current Label state
# Re-using the query pattern
$query = @"
query {
  organization(login: "Spore-Sec") {
    projectV2(number: 2) {
      items(first: 100) {
        nodes {
          id
          content {
            ... on Issue { title labels(first: 10) { nodes { name } } repository { name } }
            ... on PullRequest { title labels(first: 10) { nodes { name } } repository { name } }
          }
        }
      }
    }
  }
}
"@
$file = "fetch_items.graphql"
Set-Content $file $query
gh api graphql -F query=@$file > items_dump.json
Remove-Item $file

$j = Get-Content items_dump.json | ConvertFrom-Json
$items = $j.data.organization.projectV2.items.nodes

foreach ($item in $items) {
    $itemId = $item.id
    $title = $item.content.title
    $labels = $item.content.labels.nodes.name
    $repoName = $item.content.repository.name
    
    # Task A: Sync Size
    foreach ($key in $sizeMap.Keys) {
        if ($labels -contains $key) {
            $optId = $sizeMap[$key]
            Write-Host "Syncing Size '$key' for '$title'"
            
            $mutation = @"
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "$projectId"
    itemId: "$itemId"
    fieldId: "$sizeFieldId"
    value: { singleSelectOptionId: "$optId" }
  }) { projectV2Item { id } }
}
"@
            $mFile = "mut_size_$(Get-Random).graphql"
            Set-Content $mFile $mutation
            gh api graphql -F query=@$mFile | Out-Null
            Remove-Item $mFile
            break
        }
    }

    if (-not $repoName) {
        Write-Host "WARNING: Item '$title' has no linked repository."
    } else {
        Write-Host "  [Info] '$title' linked to $repoName."
    }
}
Write-Host "Repair Complete."
