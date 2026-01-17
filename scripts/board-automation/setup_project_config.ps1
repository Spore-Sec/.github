# PowerShell Script to Setup Project Config (Milestones & Labels)
# Actions:
# 1. Create Milestones (Phase 1, 2, 3)
# 2. Create Standard Labels (Priority, Agent, Size)

$org = "Spore-Sec"
$repos = @("website", "lead-scraper")

$milestones = @(
    @{Title="Phase 1: Coming Soon"; Desc="Launch the Waitlist/Coming Soon Page"},
    @{Title="Phase 2: Platform Alpha"; Desc="Core Scraper & Dashboard Logic"},
    @{Title="Phase 3: Automation"; Desc="Queue Systems & Scale"}
)

$labels = @(
    @{Name="priority:P0"; Color="B60205"; Desc="Critical, Blocked"},
    @{Name="priority:P1"; Color="D93F0B"; Desc="High Priority"},
    @{Name="priority:P2"; Color="0E8A16"; Desc="Normal Priority"},
    @{Name="agent:ai"; Color="6f42c1"; Desc="For AI Agents"},
    @{Name="agent:human"; Color="0075ca"; Desc="For Human Devs"},
    @{Name="size:S"; Color="0E8A16"; Desc="Small Task"},
    @{Name="size:M"; Color="FBCA04"; Desc="Medium Task"},
    @{Name="size:L"; Color="B60205"; Desc="Large Task"}
)

Write-Host "--- Configuring Milestones & Labels ---"

foreach ($repo in $repos) {
    Write-Host "`nProcessing Repo: $repo"
    
    # 1. Create Milestones
    foreach ($m in $milestones) {
        Write-Host "  Creating Milestone: $($m.Title)..."
        try {
            gh api -X POST "repos/$org/$repo/milestones" -f title="$($m.Title)" -f description="$($m.Desc)"
        } catch {
            Write-Host "    (Milestone might already exist)"
        }
    }

    # 2. Create Labels
    foreach ($l in $labels) {
        Write-Host "  Creating Label: $($l.Name)..."
        try {
            gh label create "$($l.Name)" --repo "$org/$repo" --color "$($l.Color)" --description "$($l.Desc)" --force
        } catch {
            Write-Host "    (Label might already exist)"
        }
    }
}

Write-Host "---------------------------------------------------"
Write-Host "Configuration Complete!"
Write-Host "---------------------------------------------------"
