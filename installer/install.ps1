#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive TUI installer for the Windows dotfiles environment.
.DESCRIPTION
    Presents a keyboard-navigable menu for selecting packages and features to
    install. All items are pre-selected; deselect anything you don't want.

    Navigation:  ↑ ↓
    Toggle:      Space
    Select all:  A
    Deselect:    N
    Install:     Enter
    Quit:        Q / Escape
.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -Unattended    # install everything without the TUI
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch] $Unattended
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force | Out-Null

. "$PSScriptRoot\lib\tui.ps1"

# ─── Paths ───────────────────────────────────────────────────────────────────

$Script:Root        = $PSScriptRoot
$Script:PackagesDir = Join-Path $Script:Root 'packages'
$Script:FontsDir    = Join-Path $Script:Root 'fonts'

# ─── Menu Data ───────────────────────────────────────────────────────────────

function New-MenuItem {
    param(
        [Parameter(Mandatory)] [string] $Id,
        [Parameter(Mandatory)] [string] $Group,
        [Parameter(Mandatory)] [string] $Name,
        [string] $Description = '',
        [bool]   $Selected    = $true,
        [string] $Tag         = 'feature'
    )
    [PSCustomObject]@{
        Id          = $Id
        Group       = $Group
        Name        = $Name
        Description = $Description
        Selected    = $Selected
        Tag         = $Tag
    }
}

function Get-MenuItems {
    $scoopPkgs  = @()
    $wingetPkgs = @()

    $scoopFile  = Join-Path $Script:PackagesDir 'scoop.txt'
    $wingetFile = Join-Path $Script:PackagesDir 'winget.txt'

    if (Test-Path $scoopFile) {
        $scoopPkgs = Get-Content $scoopFile |
            Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' }
    }
    if (Test-Path $wingetFile) {
        $wingetPkgs = Get-Content $wingetFile |
            Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' }
    }

    $items = [System.Collections.Generic.List[PSCustomObject]]::new()

    # ── Core ─────────────────────────────────────────────────────────────────
    @(
        New-MenuItem 'core-scoop'      'Core' 'Scoop'          'Fast Windows package manager'             $true  'feature'
        New-MenuItem 'core-pwsh'       'Core' 'PowerShell 7+'  'Latest pwsh via winget'                   $true  'feature'
        New-MenuItem 'core-psreadline' 'Core' 'PSReadLine'      'Enhanced readline for PowerShell'         $true  'feature'
        New-MenuItem 'core-node'       'Core' 'Node.js + pnpm'  'JS runtime with fast package manager'    $true  'feature'
    ) | ForEach-Object { $items.Add($_) }

    # ── Scoop Packages ───────────────────────────────────────────────────────
    foreach ($pkg in $scoopPkgs) {
        $items.Add((New-MenuItem "scoop-$pkg" 'Scoop Packages' $pkg '' $true 'scoop'))
    }

    # ── Winget Packages ──────────────────────────────────────────────────────
    foreach ($pkg in $wingetPkgs) {
        $items.Add((New-MenuItem "winget-$pkg" 'Winget Packages' $pkg '' $true 'winget'))
    }

    # ── Setup ────────────────────────────────────────────────────────────────
    @(
        New-MenuItem 'setup-fonts'       'Setup' 'Install Fonts'        'FiraCode Nerd Font, Inter, Noto Sans TC'     $true  'feature'
        New-MenuItem 'setup-profile'     'Setup' 'PowerShell Profile'   'Symlink $profile → ~/.pwsh/profile.ps1'      $true  'feature'
        New-MenuItem 'setup-wezterm-ctx' 'Setup' 'WezTerm Context Menu' 'Add "Open in WezTerm" to folder right-click' $true  'feature'
        New-MenuItem 'setup-win10-menu'  'Setup' 'Win10 Context Menu'   'Restore classic Windows 10 right-click menu'  $false 'feature'
    ) | ForEach-Object { $items.Add($_) }

    return $items
}

# ─── Installation Helpers ────────────────────────────────────────────────────

function Write-Step {
    param([Parameter(Mandatory)] [string] $Message)
    Write-Host "  ● $Message" -ForegroundColor Cyan
}

function Write-Done {
    param([string] $Message = 'Done')
    Write-Host "    ✓ $Message" -ForegroundColor Green
}

function Write-Skip {
    param([Parameter(Mandatory)] [string] $Name)
    Write-Host "    ─ $Name (already installed)" -ForegroundColor DarkGray
}

function Update-EnvironmentVariables {
    <#
    .SYNOPSIS
        Refresh the current process environment from machine and user scopes.
        Call this after installing tools that modify PATH.
    #>
    $machineEnv = [System.Environment]::GetEnvironmentVariables('Machine')
    $userEnv    = [System.Environment]::GetEnvironmentVariables('User')
    $machineEnv.GetEnumerator() | ForEach-Object {
        [System.Environment]::SetEnvironmentVariable($_.Key, $_.Value, 'Process')
    }
    $userEnv.GetEnumerator() | ForEach-Object {
        [System.Environment]::SetEnvironmentVariable($_.Key, $_.Value, 'Process')
    }
}

function Install-Font {
    <#
    .SYNOPSIS
        Install a font to the current user's fonts folder (no admin required).
        Registers it under HKCU so Windows picks it up immediately.
    #>
    param(
        [Parameter(Mandatory)] [string] $FontPath
    )

    $userFontsDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    if (-not (Test-Path $userFontsDir)) {
        New-Item -ItemType Directory -Path $userFontsDir -Force | Out-Null
    }

    $fontFile = [System.IO.Path]::GetFileName($FontPath)
    $dest     = Join-Path $userFontsDir $fontFile

    if (-not (Test-Path $dest)) {
        Copy-Item $FontPath $dest -Force
    }

    $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    $regName = [System.IO.Path]::GetFileNameWithoutExtension($FontPath) + ' (TrueType)'
    New-ItemProperty -Path $regPath -Name $regName -Value $dest -PropertyType String -Force | Out-Null
}

function Add-ContextMenuItem {
    <#
    .SYNOPSIS
        Add a "Open with <App>" entry to the Windows Explorer folder context menu.
    #>
    param(
        [Parameter(Mandatory)] [string] $AppName,
        [string] $MenuText    = '',
        [string] $CommandName = '',
        [string] $CommandFlag = ''
    )

    if (-not $MenuText) { $MenuText = "Open with $AppName" }

    $appPath = scoop prefix $AppName 2>$null
    if (-not $appPath) {
        Write-Warning "Scoop app not found: $AppName"
        return
    }

    $exePath = if ($CommandName) {
        Join-Path $appPath $CommandName
    } else {
        (Get-ChildItem $appPath -Filter '*.exe' -File -Recurse | Select-Object -First 1).FullName
    }

    if (-not (Test-Path $exePath)) {
        Write-Warning "Executable not found: $exePath"
        return
    }

    $keyPath = "HKCU:\Software\Classes\Directory\background\shell\$AppName"
    $cmdPath = "$keyPath\command"

    New-Item -Path $keyPath -Force | Out-Null
    Set-ItemProperty -Path $keyPath -Name '(default)' -Value $MenuText
    Set-ItemProperty -Path $keyPath -Name 'icon'      -Value $exePath

    New-Item -Path $cmdPath -Force | Out-Null
    Set-ItemProperty -Path $cmdPath -Name '(default)' -Value "$exePath $CommandFlag"
}

# ─── Installation Steps ──────────────────────────────────────────────────────

function Install-Selected {
    param(
        [Parameter(Mandatory)] [System.Collections.Generic.List[PSCustomObject]] $Items
    )

    [Console]::Write($SHOW_CURSOR)
    [Console]::Clear()

    Write-Host ''
    Write-Host '  Starting installation...' -ForegroundColor Cyan
    Write-Host ''

    $selected = $Items | Where-Object { $_.Selected }

    # ── Scoop ────────────────────────────────────────────────────────────────
    if ($selected | Where-Object Id -eq 'core-scoop') {
        Write-Step 'Scoop...'
        if (Test-Path "$env:USERPROFILE\scoop") {
            Write-Skip 'Scoop'
        } else {
            Invoke-RestMethod https://get.scoop.sh | Invoke-Expression
            scoop bucket add extras
            scoop bucket add versions
            Update-EnvironmentVariables
            Write-Done
        }
    }

    # ── PowerShell 7+ ────────────────────────────────────────────────────────
    if ($selected | Where-Object Id -eq 'core-pwsh') {
        Write-Step 'PowerShell 7+...'
        winget install --id Microsoft.Powershell --source winget `
            --accept-source-agreements --accept-package-agreements
        Write-Done
    }

    # ── PSReadLine ───────────────────────────────────────────────────────────
    if ($selected | Where-Object Id -eq 'core-psreadline') {
        Write-Step 'PSReadLine...'
        if (Get-Module -ListAvailable -Name PSReadLine) {
            Write-Skip 'PSReadLine'
        } else {
            Install-Module PSReadLine -Force -SkipPublisherCheck
            Write-Done
        }
    }

    # ── Node.js + pnpm ───────────────────────────────────────────────────────
    if ($selected | Where-Object Id -eq 'core-node') {
        Write-Step 'Node.js + pnpm...'
        $wingetList = winget list 2>$null | Out-String
        if ($wingetList | Select-String 'NodeJS') {
            Write-Skip 'Node.js'
        } else {
            winget install --id OpenJS.NodeJS `
                --accept-source-agreements --accept-package-agreements
            Update-EnvironmentVariables
            npm install -g pnpm
            Write-Done
        }
    }

    # ── Scoop Packages ───────────────────────────────────────────────────────
    $scoopItems = $selected | Where-Object Tag -eq 'scoop'
    if ($scoopItems) {
        Write-Step 'Scoop packages...'
        $scoopList = scoop list 2>$null | Out-String
        foreach ($item in $scoopItems) {
            if ($scoopList | Select-String -Pattern $item.Name) {
                Write-Skip $item.Name
            } else {
                scoop install $item.Name
                scoop reset $item.Name
                Write-Done $item.Name
            }
        }
    }

    # ── Winget Packages ──────────────────────────────────────────────────────
    $wingetItems = $selected | Where-Object Tag -eq 'winget'
    if ($wingetItems) {
        Write-Step 'Winget packages...'
        $wingetList = winget list 2>$null | Out-String
        foreach ($item in $wingetItems) {
            $shortName = ($item.Name -split '\.')[-1]
            if (($wingetList | Select-String $item.Name) -or ($wingetList | Select-String $shortName)) {
                Write-Skip $item.Name
            } else {
                winget install --id $item.Name `
                    --accept-source-agreements --accept-package-agreements
                Write-Done $item.Name
            }
        }
    }

    # ── Fonts ────────────────────────────────────────────────────────────────
    if ($selected | Where-Object Id -eq 'setup-fonts') {
        Write-Step 'Installing fonts...'
        if (Test-Path $Script:FontsDir) {
            Get-ChildItem $Script:FontsDir -Include '*.ttf', '*.otf' -Recurse | ForEach-Object {
                Install-Font -FontPath $_.FullName
            }
            Write-Done
        } else {
            Write-Warning "Fonts directory not found: $Script:FontsDir"
        }
    }

    # ── PowerShell Profile ───────────────────────────────────────────────────
    if ($selected | Where-Object Id -eq 'setup-profile') {
        Write-Step 'Linking PowerShell profile...'
        $source     = "$HOME\.pwsh\profile.ps1"
        $profileDir = Split-Path $profile -Parent

        if (-not (Test-Path $source)) {
            Write-Warning "Profile source not found: $source — clone the dotfiles repo first."
        } else {
            if (-not (Test-Path $profileDir)) {
                New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
            }
            try {
                New-Item -ItemType SymbolicLink -Path $profile -Target $source -Force -ErrorAction Stop | Out-Null
                Write-Done "Linked $profile → $source"
            } catch {
                Write-Warning "Symlink creation failed (may need admin or Developer Mode)."
                Write-Warning "Falling back: copying profile instead."
                Copy-Item -Path $source -Destination $profile -Force
                Write-Done "Copied $source → $profile"
            }
        }
    }

    # ── WezTerm Context Menu ─────────────────────────────────────────────────
    if ($selected | Where-Object Id -eq 'setup-wezterm-ctx') {
        Write-Step 'WezTerm context menu entry...'
        Add-ContextMenuItem -AppName 'wezterm-nightly' `
            -CommandName 'wezterm-gui.exe' `
            -CommandFlag 'start --cwd .'
        Write-Done
    }

    # ── Win10 Classic Context Menu ───────────────────────────────────────────
    if ($selected | Where-Object Id -eq 'setup-win10-menu') {
        Write-Step 'Restoring Win10 classic context menu...'
        $regPath = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name '(default)' -Value '' -Force
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Process explorer.exe
        Write-Done
    }

    Write-Host ''
    Write-Host '  ✓ Installation complete!' -ForegroundColor Green
    Write-Host ''
}

# ─── Entry Point ─────────────────────────────────────────────────────────────

$items = Get-MenuItems

if ($Unattended) {
    Install-Selected -Items $items
    exit 0
}

$result = Start-TuiMenu -Items $items `
    -Title  'Windows Dotfiles Installer' `
    -Footer '  ↑↓ Navigate   Space Toggle   A Select All   N Deselect All   Enter Install   Q Quit'

if ($null -eq $result) {
    [Console]::Write($SHOW_CURSOR)
    [Console]::Clear()
    Write-Host "`n  Cancelled.`n" -ForegroundColor Yellow
    exit 0
}

Install-Selected -Items $result
