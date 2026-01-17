# Extract Size/Effort IDs
$j = Get-Content C:\Users\User\Coding\SporeSec\Archive\SporeSec-DarkWeb-Scanner\project_map_final.json | ConvertFrom-Json
$fields = $j.data.organization.projectV2.fields.nodes

$sizeField = $fields | Where-Object { $_.name -like "*Size*" -or $_.name -like "*Effort*" }

if ($sizeField) {
    "SIZE_FIELD_ID=$($sizeField.id)"
    $sizeField.options | ForEach-Object {
        "OPTION_$($_.name)=$($_.id)"
    }
} else {
    "Size field not found"
}
