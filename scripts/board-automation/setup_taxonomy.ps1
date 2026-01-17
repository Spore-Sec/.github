# PowerShell Script to Setup Taxonomy (Labels & Project Fields)
# Actions:
# 1. Create Granular Labels (Component, Role, Type)
# 2. Configure Project Board Fields (Priority, Size, Component)

$org = "Spore-Sec"
$projectNumber = 2
$repos = @("website", "lead-scraper")

$labels = @(
    # Components
    @{Name="component:scraper"; Color="0E8A16"; Desc="Lead Scraper (Golang)"},
    @{Name="component:website"; Color="1D76DB"; Desc="Marketing Website (Next.js)"},
    @{Name="component:backend"; Color="5319E7"; Desc="Platform API (.NET)"},
    
    # Roels
    @{Name="role:frontend"; Color="C2E0C6"; Desc="Frontend Tasks"},
    @{Name="role:backend"; Color="BFD4F2"; Desc="Backend Tasks"},
    @{Name="role:devops"; Color="F9D0C4"; Desc="CI/CD & Infra"},
    
    # Types
    @{Name="type:feature"; Color="A2EEEF"; Desc="New Functionality"},
    @{Name="type:bug"; Color="d73a4a"; Desc="Something broken"},
    @{Name="type:tech-debt"; Color="0052cc"; Desc="Cleanup & Refactor"},
    @{Name="type:documentation"; Color="0075ca"; Desc="Docs & Guides"}
)

Write-Host "--- Configuring Taxonomy ---"

# 1. Apply Labels to Repos
foreach ($repo in $repos) {
    Write-Host "Applying Labels to $repo..."
    foreach ($l in $labels) {
        try {
            gh label create "$($l.Name)" --repo "$org/$repo" --color "$($l.Color)" --description "$($l.Desc)" --force
        } catch {
            Write-Host "  (Label $($l.Name) exists)"
        }
    }
}

# 2. Project Fields (Custom Fields)
# Note: This uses GraphQL or beta features. We attempt standard creation.
# If these fail, it means the CLI doesn't support field creation yet, and we must rely on Labels.
Write-Host "`nConfiguring Project Board Fields..."

# We will try to add a 'Component' Text Field
try {
    # Check if field exists first effectively by listing
    $fields = gh project field-list $projectNumber --owner $org --format json | ConvertFrom-Json
    if (-not ($fields | Where-Object { $_.name -eq "Component" })) {
        Write-Host "Creating 'Component' Field..."
        gh project field-create $projectNumber --owner $org --name "Component" --data-type text
    } else {
        Write-Host "'Component' field already exists."
    }
} catch {
    Write-Host "Could not automatically create Project Fields (API limitation). Falling back to Labels."
    Write-Host "Error: $_"
}

Write-Host "---------------------------------------------------"
Write-Host "Taxonomy Setup Complete!"
Write-Host "---------------------------------------------------"
