# ─── Aliases ─────────────────────────────────────────────────────────────────

New-Alias -Name v   -Value nvim              -ErrorAction SilentlyContinue
New-Alias -Name k   -Value kubectl           -ErrorAction SilentlyContinue
New-Alias -Name dot -Value Invoke-Dot        -ErrorAction SilentlyContinue
New-Alias -Name g   -Value Invoke-Goto       -ErrorAction SilentlyContinue
New-Alias -Name kn  -Value Set-KubeNamespace -ErrorAction SilentlyContinue

Remove-Item Alias:h -ErrorAction SilentlyContinue
New-Alias -Name h -Value helm -ErrorAction SilentlyContinue

# ─── Functions ───────────────────────────────────────────────────────────────

function Invoke-Dot {
    <#
    .SYNOPSIS
        Manage dotfiles via a bare git repository at ~/.dotfiles.
    .EXAMPLE
        dot status
        dot add .config/nvim
        dot commit -m "update nvim"
        dot push origin main
    #>
    git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" @Args
}

function Invoke-Goto {
    <#
    .SYNOPSIS
        Quick navigation to named project directories.
    .EXAMPLE
        g pr   # ~/projects
        g bp   # ~/projects/boilerplates
        g cs   # ~/projects/cheat-sheets
    #>
    param(
        [Parameter(Mandatory)]
        [string] $Location
    )

    $locations = @{
        'pr' = "$HOME/projects"
        'bp' = "$HOME/projects/boilerplates"
        'cs' = "$HOME/projects/cheat-sheets"
    }

    if ($locations.ContainsKey($Location)) {
        Set-Location -Path $locations[$Location]
    } else {
        Write-Warning "Unknown location '$Location'. Available: $($locations.Keys -join ', ')"
    }
}

function Set-KubeNamespace {
    <#
    .SYNOPSIS
        Switch the active kubectl namespace for the current context.
    .EXAMPLE
        kn default
        kn d        # shorthand for default
        kn staging
    #>
    param(
        [Parameter(Mandatory)]
        [string] $Namespace
    )

    $resolved = if ($Namespace -in 'default', 'd') { 'default' } else { $Namespace }
    kubectl config set-context --current --namespace=$resolved
}

# ─── PSReadLine ───────────────────────────────────────────────────────────────

Import-Module PSReadLine -ErrorAction SilentlyContinue

try {
    Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Chord UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Chord DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord Ctrl+p    -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Chord Ctrl+n    -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord Ctrl+h    -Function BackwardChar
    Set-PSReadLineKeyHandler -Chord Ctrl+k    -Function ForwardChar
    Set-PSReadLineOption -Colors @{ InlinePrediction = '#875f5f' }
} catch {
    Set-PSReadLineOption -PredictionSource None
}

# ─── Starship ────────────────────────────────────────────────────────────────

$ENV:STARSHIP_CONFIG = "$HOME\.starship\starship.toml"
Invoke-Expression (&starship init powershell)
