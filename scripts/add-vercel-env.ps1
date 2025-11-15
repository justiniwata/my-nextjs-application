<#
Adds POSTGRES env vars from local .env to the linked Vercel project.

Usage:
  Open PowerShell in the repository root and run:
    .\scripts\add-vercel-env.ps1

Prerequisites:
  - vercel CLI installed and logged in: `npm i -g vercel` then `vercel login`
  - Run `vercel link` to link this repo to the Vercel project (the script will also call it if not linked)

This script will attempt to add the following env vars for Development, Preview and Production:
  - POSTGRES_PRISMA_URL
  - POSTGRES_URL_NON_POOLING
  - DATABASE_URL (if present)

Notes:
  - The script runs the `vercel env add` command; the CLI may prompt if it needs more info.
  - Keep `.env` out of source control. Your repository .gitignore already ignores it.
#>

Set-StrictMode -Version Latest

function Read-EnvValue {
    param(
        [string]$Name
    )
    if (-not (Test-Path -Path '.env')) {
        Write-Error ".env file not found in repository root. Create or copy one and try again."
        exit 1
    }

    $pattern = "^$Name\s*=\s*(.*)$"
    $line = Get-Content .env | Where-Object { $_ -match $pattern }
    if (-not $line) { return $null }
    $matches = [regex]::Match($line, $pattern)
    if ($matches.Success) {
        $val = $matches.Groups[1].Value.Trim()
        # remove surrounding quotes if present
        if ($val.StartsWith('"') -and $val.EndsWith('"')) { $val = $val.Substring(1, $val.Length - 2) }
        return $val
    }
    return $null
}

if (-not (Get-Command vercel -ErrorAction SilentlyContinue)) {
    Write-Error "vercel CLI not found. Install it with: npm i -g vercel"
    exit 1
}

Write-Host "Ensuring you're logged into Vercel (vercel whoami)..."
vercel whoami
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged in — running 'vercel login' now (interactive)..."
    vercel login
    if ($LASTEXITCODE -ne 0) { Write-Error "vercel login failed. Aborting."; exit 1 }
}

Write-Host "Linking local repo to a Vercel project (vercel link)..."
vercel link

$vars = @('POSTGRES_PRISMA_URL','POSTGRES_URL_NON_POOLING','DATABASE_URL')
foreach ($name in $vars) {
    $value = Read-EnvValue -Name $name
    if (-not $value) {
        Write-Host "No value for $name found in .env — skipping"
        continue
    }

    Write-Host "Adding $name to Vercel (development)"
    # If the variable already exists, `vercel env add` will prompt — acceptable.
    vercel env add $name "$value" development
    Write-Host "Adding $name to Vercel (preview)"
    vercel env add $name "$value" preview
    Write-Host "Adding $name to Vercel (production)"
    vercel env add $name "$value" production
}

Write-Host "Done. Run 'vercel env ls' to verify or 'vercel env pull .env.development.local' to sync locally."
