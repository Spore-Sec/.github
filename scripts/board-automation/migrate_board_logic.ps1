# PowerShell Script: The Great Migration
# STRICT ID Mapping from Verification Step
$projectId = "PVT_kwDODsl_8M4BMzFe"
$statusFieldId = "PVTSSF_lADODsl_8M4BMzFezgOIliI"

$map = @{
    "Backlog" = "ff2a0256"
    "Ready" = "f17625a5"
    "Stuck" = "6e07cd4e"
    "Done" = "98236657"
    "In Progress" = "47fc9ee4"
}

Write-Host "--- Starting Migration ---"
$items = gh project item-list 2 --owner Spore-Sec --format json --limit 100 | ConvertFrom-Json

foreach ($item in $items.items) {
    $itemId = $item.id
    $title = $item.content.title
    $labels = $item.content.labels
    $state = $item.content.state # OPEN or CLOSED (for issues)
    $currentStatus = $item.status
    
    $targetOptionId = $null
    $reason = ""

    # Rule 1: Closed -> Done
    if ($state -eq "CLOSED" -and $currentStatus -ne "Done") {
        $targetOptionId = $map["Done"]
        $reason = "Issue is Closed"
    }
    # Rule 2: Blocked -> Stuck
    elseif ($labels -contains "blocked") {
        $targetOptionId = $map["Stuck"]
        $reason = "Label: blocked"
    }
    # Rule 3: Tech Debt -> Backlog
    elseif ($labels -contains "type:tech-debt") {
        $targetOptionId = $map["Backlog"]
        $reason = "Label: type:tech-debt"
    }
    # Rule 4: P0/P1 -> Ready
    elseif ($labels -contains "priority:P0" -or $labels -contains "priority:P1") {
        $targetOptionId = $map["Ready"]
        $reason = "High Priority (P0/P1)"
    }

    # Execute Move
    if ($targetOptionId) {
        Write-Host "Moving '$title'"
        Write-Host "  -> Reason: $reason"
        Write-Host "  -> Target ID: $targetOptionId"
        
        $mutation = @"
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "$projectId"
    itemId: "$itemId"
    fieldId: "$statusFieldId"
    value: { singleSelectOptionId: "$targetOptionId" }
  }) {
    projectV2Item { id }
  }
}
"@
        $file = "move_item_$(Get-Random).graphql"
        Set-Content $file $mutation
        gh api graphql -F query=@$file | Out-Null
        Remove-Item $file
    }
}
Write-Host "Migration Complete."
