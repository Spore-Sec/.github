# PowerShell Script: Sync Priority from Labels
# IDs derived from IDS_V2.TXT

$projectId = "PVT_kwDODsl_8M4BMzFe"
$priorityFieldId = "PVTSSF_lADODsl_8M4BMzFezg8AXOg"

# Map Label -> Option ID
$pMap = @{
    "priority:P0" = "262ccc92" # Critical
    "priority:P1" = "6acbee12" # High
    "priority:P2" = "04ed7323" # Medium
    "priority:P3" = "73236c57" # Low (assuming alignment)
}

Write-Host "--- Syncing Priority Field ---"

# Load items from recent dump
$j = Get-Content project_map_final.json | ConvertFrom-Json
# Wait, project_map_final was just Schema. I need Items.
# I will re-run full dump quickly primarily for Items.
gh api graphql -F query=@full_dump_query.graphql > items_fresh.json
$jItems = Get-Content items_fresh.json | ConvertFrom-Json
$items = $jItems.data.organization.projectV2.items.nodes

foreach ($item in $items) {
    $itemId = $item.id
    $title = $item.content.title
    $labels = $item.content.labels.nodes.name
    
    $targetOptionId = $null
    
    foreach ($key in $pMap.Keys) {
        if ($labels -contains $key -or $labels -contains $key.Replace("priority:","")) {
            $targetOptionId = $pMap[$key]
            Write-Host "Found Match: $key for '$title'"
            break
        }
    }
    
    if ($targetOptionId) {
        $mutation = @"
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "$projectId"
    itemId: "$itemId"
    fieldId: "$priorityFieldId"
    value: { singleSelectOptionId: "$targetOptionId" }
  }) {
    projectV2Item { id }
  }
}
"@
        $file = "p_sync_$(Get-Random).graphql"
        Set-Content $file $mutation
        gh api graphql -F query=@$file | Out-Null
        Remove-Item $file
    }
}
Write-Host "Priority Sync Complete."
