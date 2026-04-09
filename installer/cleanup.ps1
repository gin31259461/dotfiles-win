#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive Windows system cleanup.
.DESCRIPTION
    Presents a selection list of cleanup tasks. Each task shows the estimated
    reclaimable space before anything is deleted.

    Navigation:  number(s) or 'all'
    Confirm:     Enter
.PARAMETER Unattended
    Skip all confirmation prompts and run all selected tasks silently.
.EXAMPLE
    .\installer\cleanup.ps1
.EXAMPLE
    .\installer\cleanup.ps1 -Unattended
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch] $Unattended
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\lib\tui.ps1"

# ── Size helpers ──────────────────────────────────────────────────────────────

function Get-FolderSize {
    <#
    .SYNOPSIS Returns a human-readable folder size string, e.g. "3.6 GB" or "n/a".
    #>
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 'n/a' }
    try {
        $bytes = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        if (-not $bytes) { return '0 B' }
        if ($bytes -lt 1KB)  { return "$bytes B" }
        if ($bytes -lt 1MB)  { return '{0:N1} KB' -f ($bytes / 1KB) }
        if ($bytes -lt 1GB)  { return '{0:N1} MB' -f ($bytes / 1MB) }
        return '{0:N1} GB' -f ($bytes / 1GB)
    } catch { return 'n/a' }
}

function Get-ScoopCacheSize {
    $scoopRoot = if ($env:SCOOP) { $env:SCOOP } else { "$HOME\scoop" }
    Get-FolderSize (Join-Path $scoopRoot 'cache')
}

function Get-TempSize {
    Get-FolderSize $env:TEMP
}

function Get-NpmCacheSize {
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { return 'n/a' }
    try {
        $dir = & npm config get cache 2>$null
        if ($dir -and (Test-Path $dir)) { return Get-FolderSize $dir }
    } catch {}
    return 'n/a'
}

function Get-WingetCacheSize {
    $paths = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalCache"
        "$env:TEMP\WinGet"
    )
    $total = 0
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $b = (Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            if ($b) { $total += $b }
        }
    }
    if ($total -eq 0) { return '0 B' }
    if ($total -lt 1MB)  { return '{0:N1} KB' -f ($total / 1KB) }
    if ($total -lt 1GB)  { return '{0:N1} MB' -f ($total / 1MB) }
    return '{0:N1} GB' -f ($total / 1GB)
}

# ── Task definitions ──────────────────────────────────────────────────────────
# Format: Key, Label, Detail, SizeFunction
$Script:CleanupTasks = @(
    [PSCustomObject]@{ Key = 'scoop-cache';    Label = 'Scoop package cache';    Detail = 'scoop cache rm *  — download tarballs'             ; SizeFn = { Get-ScoopCacheSize   } }
    [PSCustomObject]@{ Key = 'temp-files';     Label = 'Windows Temp folder';    Detail = 'del %TEMP%\*  — build artefacts, installers'        ; SizeFn = { Get-TempSize         } }
    [PSCustomObject]@{ Key = 'npm-cache';      Label = 'npm cache';              Detail = 'npm cache clean --force'                            ; SizeFn = { Get-NpmCacheSize     } }
    [PSCustomObject]@{ Key = 'winget-cache';   Label = 'WinGet download cache';  Detail = 'LocalCache + %TEMP%\WinGet'                         ; SizeFn = { Get-WingetCacheSize  } }
    [PSCustomObject]@{ Key = 'recycle-bin';    Label = 'Recycle Bin';            Detail = 'Clear-RecycleBin -Force  — all drives'              ; SizeFn = { return '?' }         }
    [PSCustomObject]@{ Key = 'thumbnail-cache'; Label = 'Thumbnail cache';       Detail = 'Explorer thumbcache_*.db — rebuilds on demand'       ; SizeFn = { Get-FolderSize "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" } }
)

# Drop npm-cache if npm is not installed
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    $Script:CleanupTasks = $Script:CleanupTasks | Where-Object { $_.Key -ne 'npm-cache' }
}

# ── Selection UI ──────────────────────────────────────────────────────────────

function Show-TaskMenu {
    section "Select cleanup tasks"
    Write-Host "${DIM}Enter numbers (e.g. 1 3 5), a range (e.g. 1-4), or 'all'${RST}"
    Write-Host ""

    $i = 1
    foreach ($task in $Script:CleanupTasks) {
        $size = & $task.SizeFn
        $sizeColour = switch -Regex ($size) {
            'GB'  { $RED }
            'MB'  { $YLW }
            default { $GRN }
        }
        $sizePad = $size.PadLeft(8)
        Write-Host "  ${DIM}$($i.ToString().PadLeft(2)))${RST}  ${sizeColour}${sizePad}${RST}  ${BOLD}$($task.Label.PadRight(28))${RST}  ${DIM}$($task.Detail)${RST}"
        $i++
    }
    Write-Host ""
    Write-Host "${BOLD}Select:${RST} " -NoNewline
    return Read-Host
}

function Resolve-Selection {
    param([string]$Input, [int]$Total)
    $keys = @()
    $taskKeys = $Script:CleanupTasks | ForEach-Object { $_.Key }

    if ($Input.Trim() -eq 'all') { return $taskKeys }

    foreach ($token in ($Input -split '\s+')) {
        if ($token -match '^(\d+)-(\d+)$') {
            $lo = [int]$Matches[1]; $hi = [int]$Matches[2]
            for ($n = $lo; $n -le $hi; $n++) {
                if ($n -ge 1 -and $n -le $Total) { $keys += $taskKeys[$n - 1] }
                else { warn "Number $n out of range (1–$Total)" }
            }
        } elseif ($token -match '^\d+$') {
            $n = [int]$token
            if ($n -ge 1 -and $n -le $Total) { $keys += $taskKeys[$n - 1] }
            else { warn "Number $n out of range (1–$Total)" }
        }
    }
    return $keys
}

# ── Task runners ──────────────────────────────────────────────────────────────

function Invoke-ScoopCache {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) { warn "scoop not found — skipping"; return }
    Invoke-Spin "Clearing Scoop cache..." { scoop cache rm * }
    ok "Scoop cache cleared"
}

function Invoke-TempFiles {
    Invoke-Spin "Removing Temp files..." {
        Get-ChildItem $env:TEMP -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    ok "Temp folder cleaned"
}

function Invoke-NpmCache {
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { warn "npm not found — skipping"; return }
    Invoke-Spin "Clearing npm cache..." { npm cache clean --force }
    ok "npm cache cleared"
}

function Invoke-WingetCache {
    $paths = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalCache"
        "$env:TEMP\WinGet"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Invoke-Spin "Removing $p..." {
                Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    ok "WinGet cache cleared"
}

function Invoke-RecycleBin {
    Invoke-Spin "Emptying Recycle Bin..." { Clear-RecycleBin -Force -ErrorAction SilentlyContinue }
    ok "Recycle Bin emptied"
}

function Invoke-ThumbnailCache {
    $explorerProc = Get-Process -Name explorer -ErrorAction SilentlyContinue
    if ($explorerProc) {
        warn "Stopping Explorer to release thumbnail locks..."
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
    $thumbDir = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
    if (Test-Path $thumbDir) {
        Get-ChildItem $thumbDir -Filter 'thumbcache_*.db' -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
    if ($explorerProc) { Start-Process explorer }
    ok "Thumbnail cache cleared (rebuilds on next browse)"
}

$Script:Runners = @{
    'scoop-cache'    = { Invoke-ScoopCache    }
    'temp-files'     = { Invoke-TempFiles     }
    'npm-cache'      = { Invoke-NpmCache      }
    'winget-cache'   = { Invoke-WingetCache   }
    'recycle-bin'    = { Invoke-RecycleBin    }
    'thumbnail-cache' = { Invoke-ThumbnailCache }
}

# ── Main ──────────────────────────────────────────────────────────────────────

function confirm {
    param([string]$Question)
    if ($Unattended) { return $true }
    return Invoke-Confirm $Question
}

Write-Host ""
Write-Host "  ${BOLD}Windows System Cleanup${RST}"
Write-Host "  ${DIM}$('─' * 40)${RST}"

$selectedKeys = @()

if ($Unattended) {
    $selectedKeys = $Script:CleanupTasks | ForEach-Object { $_.Key }
    section "Running all tasks (unattended)"
} else {
    $raw = Show-TaskMenu
    $selectedKeys = Resolve-Selection $raw $Script:CleanupTasks.Count
}

if ($selectedKeys.Count -eq 0) { warn "Nothing selected."; exit 0 }

section "Cleanup plan"
foreach ($key in $selectedKeys) {
    $task = $Script:CleanupTasks | Where-Object { $_.Key -eq $key } | Select-Object -First 1
    Write-Host "  ${BLU}·${RST}  ${BOLD}$($task.Label.PadRight(28))${RST}  ${DIM}$($task.Detail)${RST}"
}

if (-not (confirm "Proceed with cleanup?")) { warn "Aborted."; exit 0 }

foreach ($key in $selectedKeys) {
    $task = $Script:CleanupTasks | Where-Object { $_.Key -eq $key } | Select-Object -First 1
    section $task.Label
    & $Script:Runners[$key]
}

section "Done"
ok "System cleanup complete"
