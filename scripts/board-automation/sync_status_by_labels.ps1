# PowerShell Script: Sync Status from Labels
# Logic: tech-debt -> Backlog, blocked -> Stuck, Closed -> Done

$dumpFile = "full_system_dump.json"
$j = Get-Content $dumpFile | ConvertFrom-Json

$projectId = $j.data.organization.projectV2.id
$fields = $j.data.organization.projectV2.fields.nodes
$items = $j.data.organization.projectV2.items.nodes

# 1. Map Status Options
$statusField = $fields | Where-Object { $_.name -eq "Status" }
$statusMap = @{}
$statusField.options | ForEach-Object { $statusMap[$_.name] = $_.id }

Write-Host "Status Map:"
$statusMap.Keys | ForEach-Object { Write-Host "  $_ -> $($statusMap[$_])" }

# 2. Iterate Items
foreach ($item in $items) {
    $itemId = $item.id
    
    # Extract Issue Data
    if ($item.content.labels) {
        $labels = $item.content.labels.nodes.name
        $state = $item.content.state
        $title = $item.content.title
        
        $targetStatus = $null
        
        # Rule 1: Closed -> Done
        if ($state -eq "CLOSED" -or $state -eq "MERGED") {
             $targetStatus = "Done"
        }
        # Rule 2: Blocked -> Stuck
        elseif ($labels -contains "blocked") {
             $targetStatus = "Stuck"
        }
        # Rule 3: Tech Debt -> Backlog (Only if Open)
        elseif ($labels -contains "type:tech-debt" -or $labels -contains "tech-debt") {
             $targetStatus = "Backlog"
        }
        
        if ($targetStatus) {
            $optionId = $statusMap[$targetStatus]
            
            # Check if need to update (simple check)
            # Fetching current status value is hard from this structure without parsing 'fieldValues'.
            # We will just FORCE update for safety.
            
            if ($optionId) {
                Write-Host "Syncing '$title' -> $targetStatus ($optionId)"
                
                $mutation = @"
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "$projectId"
    itemId: "$itemId"
    fieldId: "$($statusField.id)"
    value: { singleSelectOptionId: "$optionId" }
  }) {
    projectV2Item { id }
  }
}
"@
                $file = "sync_item_$(Get-Random).graphql"
                Set-Content $file $mutation
                gh api graphql -F query=@$file | Out-Null
                Remove-Item $file
            }
        }
    }
}
Write-Host "Sync Complete."
