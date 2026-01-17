# Dump ALL fields
$j = Get-Content project_map_final.json | ConvertFrom-Json
$fields = $j.data.organization.projectV2.fields.nodes
$fields | Select-Object name, id | Format-Table -AutoSize
