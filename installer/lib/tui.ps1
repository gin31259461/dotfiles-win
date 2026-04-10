#Requires -Version 5.1
<#
.SYNOPSIS
    Shared TUI helpers for dotfile scripts.
.DESCRIPTION
    Dot-source this file at the top of any installer script:

        . "$PSScriptRoot\lib\tui.ps1"       # from installer/ scripts
        . "$PSScriptRoot\installer\lib\tui.ps1"  # from dotfiles.ps1 at $HOME

    Provides:
      · ANSI colour constants ($RED $GRN $YLW $BLU $DIM $BOLD $RST $CYN …)
      · Print helpers: die  ok  warn  note  step  section
      · Invoke-Confirm — y/N readline prompt
      · Invoke-Spin    — step header + command execution
      · Start-TuiMenu  — keyboard-navigable full-screen checkbox menu
#>

# ── VT processing ─────────────────────────────────────────────────────────────
# Enable ANSI escape code processing on Windows Console (all PS versions).
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

try {
    if (-not ('TuiHelper.TuiVtHelper' -as [type])) {
        $sig = '
            [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int n);
            [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m);
            [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);
        '
        Add-Type -Name 'TuiVtHelper' -Namespace 'TuiHelper' -MemberDefinition $sig -ErrorAction Stop | Out-Null
    }
    $h = [TuiHelper.TuiVtHelper]::GetStdHandle(-11)
    $m = 0u
    [TuiHelper.TuiVtHelper]::GetConsoleMode($h, [ref]$m) | Out-Null
    [TuiHelper.TuiVtHelper]::SetConsoleMode($h, $m -bor 4) | Out-Null   # ENABLE_VT_PROCESSING
} catch { }

# ── Colour constants ──────────────────────────────────────────────────────────
$ESC  = [char]27
$RED  = "${ESC}[31m"
$GRN  = "${ESC}[32m"
$YLW  = "${ESC}[33m"
$BLU  = "${ESC}[34m"
$DIM  = "${ESC}[2m"
$BOLD = "${ESC}[1m"
$RST  = "${ESC}[0m"

# Extended palette (used by interactive TUI menu)
$CYN  = "${ESC}[96m"   # bright cyan
$LGRN = "${ESC}[92m"   # bright green
$GRY  = "${ESC}[90m"   # dark gray
$WHT  = "${ESC}[97m"   # bright white

# Cursor / screen control (used by interactive TUI menu)
$HIDE_CURSOR  = "${ESC}[?25l"
$SHOW_CURSOR  = "${ESC}[?25h"
$CURSOR_HOME  = "${ESC}[H"
$CLEAR_SCREEN = "${ESC}[2J"
$CLR_TO_EOL   = "${ESC}[K"
$CLR_TO_BOT   = "${ESC}[J"

# ── Print helpers ─────────────────────────────────────────────────────────────

function die {
    <#
    .SYNOPSIS Fatal error — prints message to stderr and exits with code 1.
    #>
    param([Parameter(Mandatory)][string]$Message)
    [Console]::Error.WriteLine("`n${RED}✗${RST}  ${Message}`n")
    exit 1
}

function ok {
    <#
    .SYNOPSIS Success line — green checkmark.
    #>
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "${GRN}✔${RST}  ${Message}"
}

function warn {
    <#
    .SYNOPSIS Warning line — yellow exclamation.
    #>
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "${YLW}!${RST}  ${Message}"
}

function note {
    <#
    .SYNOPSIS Dim informational line.
    #>
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "${DIM}${Message}${RST}"
}

function step {
    <#
    .SYNOPSIS In-progress step — blue chevron.
    #>
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "${BLU}›${RST}  ${Message}"
}

function section {
    <#
    .SYNOPSIS Bold section header with blank lines before and after.
    #>
    param([Parameter(Mandatory)][string]$Title)
    Write-Host ""
    Write-Host "${BOLD}${BLU}◆${RST}  ${BOLD}${Title}${RST}"
    Write-Host ""
}

# ── Invoke-Confirm ─────────────────────────────────────────────────────────────
function Invoke-Confirm {
    <#
    .SYNOPSIS
        Readline y/N confirmation prompt.
    .DESCRIPTION
        Prints "?  Question  [y/N]" and reads a line.
        Returns $true on y/yes, $false otherwise.
    .EXAMPLE
        if (Invoke-Confirm "Continue?") { ... }
    #>
    param([Parameter(Mandatory)][string]$Question)
    Write-Host ""
    Write-Host "${BLU}?${RST}  ${Question}  ${DIM}[y/N]${RST} " -NoNewline
    $answer = Read-Host
    return ($answer -match '^[Yy](es)?$')
}

# ── Invoke-Spin ───────────────────────────────────────────────────────────────
function Invoke-Spin {
    <#
    .SYNOPSIS
        Prints a step header then executes a scriptblock.
    .DESCRIPTION
        Equivalent to the Arch 'spin TITLE CMD ARGS' helper.
        Displays a step line, then runs the provided scriptblock.
    .EXAMPLE
        Invoke-Spin "Cloning repo..." { git clone $url $dest }
        Invoke-Spin "Installing packages..." { scoop install $pkg }
    #>
    param(
        [Parameter(Mandatory)] [string]      $Title,
        [Parameter(Mandatory)] [scriptblock] $Command
    )
    step $Title
    & $Command
}

# ── Interactive selection menu ─────────────────────────────────────────────────

function Show-TuiMenu {
    <#
    .SYNOPSIS
        Renders the interactive selection menu to the console.
    .DESCRIPTION
        Called by Start-TuiMenu on every keypress for flicker-free in-place
        redraw using ANSI sequences. Items may carry optional Hint / HintColor
        fields (e.g. disk-size info) that are shown before the item name.
    .PARAMETER Items
        List of PSCustomObject items. Required fields per item:
          Name        [string]  Display name.
          Selected    [bool]    Whether the checkbox is checked.
        Optional fields:
          Description [string]  Right-side detail text.
          Group       [string]  Section heading (empty = no heading).
          Hint        [string]  Short label shown before Name (e.g. "3.6 GB").
          HintColor   [string]  ANSI colour string for Hint.
    .PARAMETER Cursor
        Zero-based index of the currently highlighted item.
    .PARAMETER Title
        Text centred in the header box.
    .PARAMETER Footer
        Help-key line shown at the bottom of the menu.
    #>
    param(
        [Parameter(Mandatory)] [System.Collections.Generic.List[PSCustomObject]] $Items,
        [Parameter(Mandatory)] [int]    $Cursor,
        [string] $Title  = 'Select',
        [string] $Footer = '  ↑↓ Navigate   Space Toggle   A Select All   N Deselect All   Enter Confirm   Q Quit'
    )

    $eol = "${RST}${CLR_TO_EOL}`n"
    $sb  = [System.Text.StringBuilder]::new(8192)

    if ($Script:TuiMenuFirstDraw) {
        $Script:TuiMenuFirstDraw = $false
        $sb.Append($CLEAR_SCREEN) | Out-Null
    }
    $sb.Append($CURSOR_HOME).Append($HIDE_CURSOR) | Out-Null

    # ── Header ────────────────────────────────────────────────────────────────
    $boxInner = 53
    $titleLen = $Title.Length
    $padLeft  = [Math]::Max(0, [Math]::Floor(($boxInner - $titleLen) / 2))
    $padRight = [Math]::Max(0, $boxInner - $titleLen - $padLeft)
    $titleRow = ' ' * $padLeft + $Title + ' ' * $padRight

    $sb.Append($eol) | Out-Null
    $sb.Append($CYN).Append('  ╭─────────────────────────────────────────────────────╮').Append($eol) | Out-Null
    $sb.Append($CYN).Append("  │$titleRow│").Append($eol) | Out-Null
    $sb.Append($CYN).Append('  ╰─────────────────────────────────────────────────────╯').Append($eol) | Out-Null
    $sb.Append($eol) | Out-Null

    # ── Items ─────────────────────────────────────────────────────────────────
    $currentGroup = $null
    $i = 0

    foreach ($item in $Items) {
        $group = if ($null -ne $item.PSObject.Properties['Group']) { $item.Group } else { '' }
        if ($group -and $group -ne $currentGroup) {
            $currentGroup = $group
            $pad = '─' * [Math]::Max(1, 42 - $group.Length)
            $sb.Append($GRY).Append("  ── $group $pad").Append($eol) | Out-Null
        }

        $isActive   = ($i -eq $Cursor)
        $checkMark  = if ($item.Selected) { [char]0x2713 } else { ' ' }
        $arrow      = if ($isActive) { '▶' } else { ' ' }
        $checkColor = if ($item.Selected) { $LGRN } else { $GRY }
        $nameColor  = if ($isActive) { $CYN } else { $WHT }
        $desc       = if ($item.PSObject.Properties['Description'] -and $item.Description) { $item.Description } else { '' }
        $hasHint    = $item.PSObject.Properties['Hint'] -and $item.Hint
        $hint       = if ($hasHint) { $item.Hint } else { '' }
        $hintColor  = if ($hasHint -and $item.PSObject.Properties['HintColor'] -and $item.HintColor) { $item.HintColor } else { $GRY }

        $sb.Append("  $arrow ") | Out-Null
        $sb.Append($GRY).Append('[') | Out-Null
        $sb.Append($checkColor).Append($checkMark) | Out-Null
        $sb.Append($GRY).Append('] ') | Out-Null

        if ($hint) {
            $sb.Append($hintColor).Append($hint.PadLeft(8)).Append($RST).Append('  ') | Out-Null
            $sb.Append($nameColor).Append($item.Name.PadRight(20)) | Out-Null
        } else {
            $sb.Append($nameColor).Append($item.Name.PadRight(28)) | Out-Null
        }

        $sb.Append($GRY).Append($desc).Append($eol) | Out-Null
        $i++
    }

    # ── Footer ────────────────────────────────────────────────────────────────
    $sb.Append($eol) | Out-Null
    $sb.Append($GRY).Append($Footer).Append($eol) | Out-Null
    $sb.Append($CLR_TO_BOT) | Out-Null   # clear any leftover lines below

    [Console]::Write($sb.ToString())
}

function Start-TuiMenu {
    <#
    .SYNOPSIS
        Runs the interactive keyboard-navigable selection TUI.
    .DESCRIPTION
        Displays a full-screen checkbox menu and handles keyboard input.
        Returns the Items list (with Selected updated) when the user presses
        Enter, or $null when they press Q / Escape to cancel.
    .PARAMETER Items
        List of PSCustomObject items — see Show-TuiMenu for field details.
    .PARAMETER Title
        Text shown in the menu header box.
    .PARAMETER Footer
        Help-key hint line shown at the bottom.
    .OUTPUTS
        [System.Collections.Generic.List[PSCustomObject]] or $null on cancel.
    .EXAMPLE
        $result = Start-TuiMenu -Items $items -Title 'Windows Dotfiles Installer' `
                                -Footer '  ↑↓ Navigate   Space Toggle   Enter Install   Q Quit'
        if ($null -eq $result) { exit 0 }
        $selected = $result | Where-Object { $_.Selected }
    #>
    param(
        [Parameter(Mandatory)] [System.Collections.Generic.List[PSCustomObject]] $Items,
        [string] $Title  = 'Select',
        [string] $Footer = '  ↑↓ Navigate   Space Toggle   A Select All   N Deselect All   Enter Confirm   Q Quit'
    )

    $Script:TuiMenuFirstDraw = $true
    $cursor   = 0
    $maxIndex = $Items.Count - 1

    while ($true) {
        Show-TuiMenu -Items $Items -Cursor $cursor -Title $Title -Footer $Footer
        $key = [Console]::ReadKey($true)

        switch ($key.Key) {
            'UpArrow'                    { $cursor = [Math]::Max(0, $cursor - 1) }
            'DownArrow'                  { $cursor = [Math]::Min($maxIndex, $cursor + 1) }
            'Spacebar'                   { $Items[$cursor].Selected = -not $Items[$cursor].Selected }
            'A'                          { $Items | ForEach-Object { $_.Selected = $true } }
            'N'                          { $Items | ForEach-Object { $_.Selected = $false } }
            'Enter'                      { return $Items }
            { $_ -in 'Q', 'Escape' }    { return $null }
        }
    }
}
