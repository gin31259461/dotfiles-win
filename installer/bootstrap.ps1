#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap dotfiles onto a new machine.
.DESCRIPTION
    Clones the dotfiles bare repository into ~/.dotfiles and copies all tracked
    files into $HOME using robocopy. Supports a fork-owner workflow:

    · If -Repo matches the default (or memory file) → clone directly via SSH
      (HTTPS fallback if no SSH key is present).
    · If -Repo differs from the effective default → clone default repo via HTTPS
      as a base, then set your SSH URL as origin and save it to ~/.dotfiles-repo
      so future machines pick the right fork automatically.

    Run once on a fresh machine. Optionally calls .\install.ps1 afterwards.
.PARAMETER Repo
    SSH URL (or user/repo shorthand) of your dotfiles fork.
    Formats:  git@github.com:you/dotfiles-win.git   or   you/dotfiles-win
    Default comes from ~/.dotfiles-repo if present, else the hardcoded default.
.PARAMETER DotfilesDir
    Path for the bare git repository. Default: ~/.dotfiles
.PARAMETER Yes
    Non-interactive — skip all optional prompts and accept defaults.
.EXAMPLE
    .\installer\bootstrap.ps1
.EXAMPLE
    .\installer\bootstrap.ps1 -Repo 'git@github.com:you/dotfiles-win.git'
.EXAMPLE
    .\installer\bootstrap.ps1 -Yes
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $Repo        = '',
    [string] $DotfilesDir = "$HOME/.dotfiles",
    [switch] $Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue | Out-Null

. "$PSScriptRoot\lib\tui.ps1"

# ── Defaults (overridden by memory file at runtime) ───────────────────────────
$DefaultRepoSsh   = 'git@github.com:gin31259461/dotfiles-win.git'
$DefaultRepoHttps = 'https://github.com/gin31259461/dotfiles-win.git'
$DotfilesRepoFile = "$HOME/.dotfiles-repo"

$RepoSsh   = $DefaultRepoSsh
$RepoHttps = $DefaultRepoHttps

function Invoke-Dot {
    git --git-dir=$DotfilesDir --work-tree=$HOME @Args
}

# ── Load memory file ──────────────────────────────────────────────────────────
# ~/.dotfiles-repo (if present) overrides the hardcoded defaults so a fork
# owner's bootstrap.ps1 auto-targets the right repo on any new machine.
if (Test-Path $DotfilesRepoFile) {
    $mem = [System.IO.File]::ReadAllText($DotfilesRepoFile).Trim()
    if ($mem) {
        $DefaultRepoSsh = $mem
        if ($mem -match '^git@github\.com:(.+?)(?:\.git)?$') {
            $DefaultRepoHttps = "https://github.com/$($Matches[1]).git"
        } else {
            $DefaultRepoHttps = ''
        }
        $RepoSsh   = $DefaultRepoSsh
        $RepoHttps = $DefaultRepoHttps
    }
}

# ── URL resolution helpers ────────────────────────────────────────────────────

function Resolve-RepoUrls {
    param([string]$Input)
    if ($Input -match '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        $slug = $Input -replace '\.git$', ''
        $script:RepoSsh   = "git@github.com:${slug}.git"
        $script:RepoHttps = "https://github.com/${slug}.git"
    } elseif ($Input -match '^git@github\.com:(.+?)(?:\.git)?$') {
        $slug = $Matches[1]
        $script:RepoSsh   = "git@github.com:${slug}.git"
        $script:RepoHttps = "https://github.com/${slug}.git"
    } elseif ($Input -match '^git@') {
        $script:RepoSsh   = $Input
        $script:RepoHttps = ''
    } else {
        die "Unrecognised repo format: '$Input'`nUse: user/repo  or  git@github.com:user/repo.git"
    }
}

function Read-RepoUrl {
    Write-Host ""
    Write-Host "${BLU}?${RST}  Your dotfiles SSH URL  ${DIM}(e.g. git@github.com:you/dotfiles-win.git  or  you/dotfiles-win)${RST}"
    Write-Host "  " -NoNewline
    return Read-Host
}

function confirm {
    param([string]$Question)
    if ($Yes) { return $true }
    return Invoke-Confirm $Question
}

# ── Banner ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ${BOLD}Dotfiles Bootstrap${RST}  ${DIM}Windows${RST}"
Write-Host "  ${DIM}$('─' * 44)${RST}"

# ── Prerequisites ─────────────────────────────────────────────────────────────

section "Prerequisites"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    die "git not found.`nInstall from https://git-scm.com or: winget install Git.Git"
}
ok "git $(git --version)"

# ── Dotfiles repository ───────────────────────────────────────────────────────

section "Dotfiles repository"

if (Test-Path $DotfilesDir) {
    ok "Bare repo already present at $DotfilesDir — skipping clone"
    # Ensure memory file exists even when repo was cloned manually
    if (-not (Test-Path $DotfilesRepoFile)) {
        try {
            $currentRemote = & git --git-dir=$DotfilesDir remote get-url origin 2>$null
            if ($currentRemote) {
                [System.IO.File]::WriteAllText($DotfilesRepoFile, $currentRemote.Trim())
                note "Saved existing remote to $DotfilesRepoFile"
            }
        } catch { }
    }
} else {
    # Determine effective SSH URL: flag > interactive > stored > default
    $storedSsh = if (Test-Path $DotfilesRepoFile) {
        [System.IO.File]::ReadAllText($DotfilesRepoFile).Trim()
    } else { '' }

    if ($Repo) {
        Resolve-RepoUrls $Repo
    } elseif (-not $Yes) {
        $label = if ($storedSsh) { $storedSsh } else { "$DefaultRepoSsh (default)" }
        if (-not (Invoke-Confirm "Use dotfiles repo: ${label}?")) {
            $customRepo = Read-RepoUrl
            if (-not $customRepo) { die "No repository provided." }
            Resolve-RepoUrls $customRepo
        } elseif ($storedSsh) {
            Resolve-RepoUrls $storedSsh
        }
    } elseif ($storedSsh) {
        Resolve-RepoUrls $storedSsh
    }

    note "Repo SSH:   $RepoSsh"
    note "Repo HTTPS: $RepoHttps"

    # New remote = user's SSH URL differs from the stored/default
    $newSshRemote = ($RepoSsh -and ($RepoSsh -ne $storedSsh) -and ($RepoSsh -ne $DefaultRepoSsh))

    # Choose clone URL
    $cloneUrl = if ($newSshRemote) {
        note "New SSH remote detected — cloning default as base"
        $DefaultRepoHttps
    } elseif ($RepoSsh -match '^git@github\.com:') {
        # Test SSH connectivity (exit 1 = authenticated, no shell access = OK)
        $null = & ssh -T git@github.com -o BatchMode=yes -o ConnectTimeout=5 2>&1
        if ($LASTEXITCODE -eq 1) { $RepoSsh } else {
            warn "No SSH access to GitHub — using HTTPS"
            $RepoHttps
        }
    } else {
        if ($RepoSsh) { $RepoSsh } else { $RepoHttps }
    }

    if (-not $cloneUrl) { die "No valid repository URL resolved." }

    $tmpDir = Join-Path $env:TEMP 'dotfiles-bootstrap'
    if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }

    Invoke-Spin "Cloning $cloneUrl..." {
        & git clone --separate-git-dir=$DotfilesDir $cloneUrl $tmpDir
        if ($LASTEXITCODE -ne 0) { die "Clone failed — check URL and network." }
    }

    section "Deploying to HOME"
    Invoke-Spin "Copying files to $HOME..." {
        & robocopy $tmpDir $HOME /E /XD .git | Out-Null
    }
    Remove-Item $tmpDir -Recurse -Force
    ok "Files deployed to $HOME"

    # Wire SSH remote and save memory file
    if ($newSshRemote) {
        Invoke-Dot remote set-url origin $RepoSsh
        ok "Remote origin → $RepoSsh"

        # Bake the fork's URL into the deployed bootstrap.ps1 so future
        # machines bootstrapped from this fork need no -Repo flag.
        $bs = "$HOME\installer\bootstrap.ps1"
        if (Test-Path $bs) {
            $lines = Get-Content $bs
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^\$DefaultRepoSsh\s*=') {
                    $lines[$i] = "`$DefaultRepoSsh   = '$RepoSsh'"
                } elseif ($lines[$i] -match '^\$DefaultRepoHttps\s*=' -and $RepoHttps) {
                    $lines[$i] = "`$DefaultRepoHttps = '$RepoHttps'"
                }
            }
            $utf8bom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($bs, $lines, $utf8bom)
            ok "Baked fork URL into bootstrap.ps1"
        }
    }

    if ($RepoSsh) {
        [System.IO.File]::WriteAllText($DotfilesRepoFile, $RepoSsh)
        note "Saved SSH URL to $DotfilesRepoFile"
    }
}

# ── Configure ─────────────────────────────────────────────────────────────────

section "Configuration"
Invoke-Dot config --local status.showUntrackedFiles no
ok "status.showUntrackedFiles = no"

# ── Submodules ────────────────────────────────────────────────────────────────

section "Submodules"
Invoke-Spin "Initialising submodules..." { Invoke-Dot submodule update --init --recursive }
ok "Submodules ready"

# ── Install packages ──────────────────────────────────────────────────────────

section "Install packages"
$installScript = "$HOME\installer\install.ps1"
if ((Test-Path $installScript) -and (confirm "Run install.ps1 now?")) {
    & $installScript
} elseif (-not (Test-Path $installScript)) {
    note "install.ps1 not found — skipping"
} else {
    note "Run .\installer\install.ps1 later to install packages and features"
}

# ── Done ──────────────────────────────────────────────────────────────────────

section "Done"
ok "Bootstrap complete"
note "Open a new terminal to load the PowerShell profile"
note "Use 'dot status' to inspect your dotfiles"
note "Use 'dotfiles.ps1' to sync config changes back to the repo"
Write-Host ""
