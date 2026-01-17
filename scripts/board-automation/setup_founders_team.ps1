# PowerShell Script to Setup "Founders" Team
# Actions:
# 1. Create Team "Founders"
# 2. Add Members (AngelRattner, Mahdy-gribkov, SporeSec)
# 3. Grant Team ADMIN access to repos

$org = "Spore-Sec"
$team = "founders"
$members = @("AngelRattner", "Mahdy-gribkov", "SporeSec")
$repos = @("website", "lead-scraper")

Write-Host "--- Setting up Founders Team ---"

# --- 1. Create Team ---
Write-Host "Creating Team '$team'..."
try {
    gh api -X POST "orgs/$org/teams" -f name="$team" -f privacy="closed"
    Write-Host "Team created."
} catch {
    Write-Host "Team might already exist or error occurred : $_"
}

# --- 2. Add Members ---
# We need the Team Slug (usually strictly lowercase 'founders')
foreach ($user in $members) {
    Write-Host "Adding $user to Team..."
    try {
        # 'maintainer' role within the team gives them power over the team itself
        gh api -X PUT "orgs/$org/teams/$team/memberships/$user" -f role="maintainer"
        Write-Host "Added $user."
    } catch {
        Write-Host "Failed to add $user : $_"
    }
}

# --- 3. Grant Repo Access ---
foreach ($repo in $repos) {
    Write-Host "Granting Admin Access to $repo..."
    try {
        # Permission: 'admin'
        gh api -X PUT "orgs/$org/teams/$team/repos/$org/$repo" -f permission="admin"
        Write-Host "Access granted."
    } catch {
        Write-Host "Failed to grant access to $repo : $_"
    }
}

Write-Host "---------------------------------------------------"
Write-Host "Founders Team Setup Complete!"
Write-Host "Check Team: https://github.com/orgs/$org/teams/$team"
Write-Host "---------------------------------------------------"
