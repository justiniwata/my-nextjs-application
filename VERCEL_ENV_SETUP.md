# Vercel Environment Setup Helper

This file explains how to add your local database environment variables to your Vercel Project so deployed instances can connect to the same database your local app uses.

What this does
- Uses the `vercel` CLI to link your local repo to a Vercel project.
- Adds the following environment variables to the selected Vercel project environments (Development / Preview / Production):
  - `POSTGRES_PRISMA_URL`
  - `POSTGRES_URL_NON_POOLING`
  - `DATABASE_URL` (optional)

Prerequisites
- `vercel` CLI installed: `npm i -g vercel`
- You are signed in: `vercel login`
- You have access to the target Team / Project on Vercel

Quick interactive steps (recommended)

1. Login and link your repo to the project (interactive):

```powershell
vercel login
vercel link
```

2. Add env vars interactively. For each variable run the add command and paste the value from your local `.env` when prompted:

```powershell
vercel env add POSTGRES_PRISMA_URL
vercel env add POSTGRES_URL_NON_POOLING
vercel env add DATABASE_URL   # optional
```

Choose the environment(s) when prompted (development / preview / production).

Non-interactive helper (PowerShell)

The following PowerShell snippet attempts to read values from your local `.env` and call the `vercel` CLI to add them. It may work in most setups, but you can fall back to the interactive commands above if any error occurs.

Save and run this from the project root as an admin PowerShell session if you prefer:

```powershell
# Read value helper
function Get-EnvValue($name) {
  if (-Not (Test-Path '.env')) { Write-Error '.env not found in repo root'; exit 1 }
  $line = Get-Content .env | Select-String "^$name=" -SimpleMatch
  if (-not $line) { return $null }
  $val = $line.ToString().Split('=')[1..] -join '='
  return $val.Trim('"')
}

# Ensure vercel CLI is available
if (-not (Get-Command vercel -ErrorAction SilentlyContinue)) { Write-Host 'Please install vercel CLI: npm i -g vercel'; exit 1 }

vercel whoami
if ($LASTEXITCODE -ne 0) { vercel login }

vercel link

$names = @('POSTGRES_PRISMA_URL','POSTGRES_URL_NON_POOLING','DATABASE_URL')
foreach ($n in $names) {
  $v = Get-EnvValue $n
  if ($v) {
    Write-Host "Adding $n to Vercel (development + preview + production)"
    # Try inline add (may prompt); if it fails, print manual instructions
    vercel env add $n "$v" development || Write-Host "Failed non-interactive add for $n. Run: vercel env add $n and paste the value when prompted."
    vercel env add $n "$v" preview || Write-Host "Failed non-interactive add for $n (preview)."
    vercel env add $n "$v" production || Write-Host "Failed non-interactive add for $n (production)."
  } else {
    Write-Host "No value found for $n in .env; skipping"
  }
}
```

Security
- The script reads secret values from `.env` in your working directory. Keep `.env` out of version control (your `.gitignore` already ignores it).

If you want me to prepare these commands in a ready-to-run PowerShell script file, tell me and I will add it to the repository.
