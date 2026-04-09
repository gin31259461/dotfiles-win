#Requires -Version 5.1
<#
.SYNOPSIS
    Shared TUI helpers for dotfile scripts.
.DESCRIPTION
    Dot-source this file at the top of any installer script:

        . "$PSScriptRoot\lib\tui.ps1"       # from installer/ scripts
        . "$PSScriptRoot\installer\lib\tui.ps1"  # from dotfiles.ps1 at $HOME

    Provides:
      · ANSI colour constants ($RED $GRN $YLW $BLU $DIM $BOLD $RST)
      · Print helpers: die  ok  warn  note  step  section
      · Invoke-Confirm — y/N readline prompt
      · Invoke-Spin    — step header + command execution
#>

# ── VT processing ─────────────────────────────────────────────────────────────
# Enable ANSI escape code processing on Windows Console (PS 5.1 needs this).
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ($PSVersionTable.PSVersion.Major -lt 7) {
    try {
        if (-not ([Management.Automation.PSTypeName]'TuiVtHelper').Type) {
            $sig = '
                [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int n);
                [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m);
                [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);
            '
            Add-Type -Name 'TuiVtHelper' -MemberDefinition $sig -ErrorAction Stop | Out-Null
        }
        $h = [TuiVtHelper]::GetStdHandle(-11)
        $m = 0u
        [TuiVtHelper]::GetConsoleMode($h, [ref]$m) | Out-Null
        [TuiVtHelper]::SetConsoleMode($h, $m -bor 4) | Out-Null   # ENABLE_VT_PROCESSING
    } catch { }
}

# ── Colour constants ──────────────────────────────────────────────────────────
$ESC  = [char]27
$RED  = "${ESC}[31m"
$GRN  = "${ESC}[32m"
$YLW  = "${ESC}[33m"
$BLU  = "${ESC}[34m"
$DIM  = "${ESC}[2m"
$BOLD = "${ESC}[1m"
$RST  = "${ESC}[0m"

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
