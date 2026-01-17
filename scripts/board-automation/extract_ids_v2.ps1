# PowerShell Script to Extract IDs Robustly
$j = Get-Content project_map_final.json | ConvertFrom-Json
$fields = $j.data.organization.projectV2.fields.nodes

$output = @()

foreach ($f in $fields) {
    if ($f.name -eq "Priority") {
        $output += "PRIORITY_FIELD_ID=$($f.id)"
        if ($f.options) {
            foreach ($o in $f.options) {
                $output += "PRIORITY_OPTION_$($o.name)=$($o.id)"
            }
        }
    }
    elseif ($f.name -eq "Size") {
        $output += "SIZE_FIELD_ID=$($f.id)"
        if ($f.options) {
            foreach ($o in $f.options) {
                $output += "SIZE_OPTION_$($o.name)=$($o.id)"
            }
        }
    }
    elseif ($f.name -eq "Target Date") {
        $output += "TARGET_DATE_ID=$($f.id)"
    }
}

$output | Out-File ids_v2.txt -Encoding UTF8
Get-Content ids_v2.txt
