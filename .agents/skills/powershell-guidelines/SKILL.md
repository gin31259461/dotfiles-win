---
name: powershell-guidelines
description: Provides PowerShell coding conventions for this repo — naming, parameters, pipeline, error handling, and documentation style. Load when creating or editing .ps1 or .psm1 files.
---

# PowerShell Guidelines

Apply these conventions to all `.ps1` and `.psm1` files in this repository.

## When to Use

- Creating a new `.ps1` or `.psm1` file
- Editing an existing PowerShell file
- Reviewing PowerShell code for style compliance
- Writing advanced functions with parameters, pipeline support, or error handling

## When Not to Use

- Writing interactive shell one-liners (aliases are fine in the shell)
- Writing in other languages (Python, TypeScript, etc.)
- Editing non-code configuration files

## Naming

- **Verb-Noun format**: Use approved verbs (`Get-Verb`), singular PascalCase nouns, no special characters.
- **Parameters**: PascalCase, clear descriptive names, singular form unless always multiple.
- **Variables**: PascalCase for public, camelCase for private; avoid abbreviations.
- **No aliases in scripts**: Use full cmdlet names (`Get-ChildItem` not `gci`). Aliases are acceptable for interactive shell use only.

```powershell
function Get-UserProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Username,
        [Parameter()]
        [ValidateSet('Basic', 'Detailed')]
        [string]$ProfileType = 'Basic'
    )
    process { }
}
```

## Parameter Design

- Use common parameter names (`Path`, `Name`, `Force`) and follow built-in cmdlet conventions.
- Use `[switch]` for boolean flags — avoid `$true`/`$false` parameters.
- Use `ValidateSet` for limited options; enable tab completion.

```powershell
function Set-ResourceConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter()]
        [ValidateSet('Dev', 'Test', 'Prod')]
        [string]$Environment = 'Dev',
        [Parameter()]
        [switch]$Force,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Tags
    )
    process { }
}
```

## Pipeline and Output

- Use `ValueFromPipeline` / `ValueFromPipelineByPropertyName` for pipeline input.
- Implement `Begin`/`Process`/`End` blocks for pipeline functions.
- Return rich objects (`PSCustomObject`), not formatted text. Avoid `Write-Host` for data output.
- Default to no output for action cmdlets; implement `-PassThru` to optionally return the object.

```powershell
function Update-ResourceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name,
        [Parameter(Mandatory)]
        [ValidateSet('Active', 'Inactive', 'Maintenance')]
        [string]$Status,
        [Parameter()]
        [switch]$PassThru
    )
    begin { Write-Verbose 'Starting…'; $ts = Get-Date }
    process {
        $r = [PSCustomObject]@{ Name=$Name; Status=$Status; LastUpdated=$ts; UpdatedBy=$env:USERNAME }
        if ($PassThru) { Write-Output $r }
    }
    end { Write-Verbose 'Done' }
}
```

## Error Handling

- Use `[CmdletBinding(SupportsShouldProcess = $true)]` and set `ConfirmImpact` for destructive ops.
- Use `try`/`catch`; prefer `$PSCmdlet.WriteError()` over `Write-Error` and `$PSCmdlet.ThrowTerminatingError()` over `throw`.
- Construct proper `ErrorRecord` objects with category, target, and exception details.
- Use `Write-Verbose` for details, `Write-Warning` for warnings, `Write-Error` for non-terminating errors.
- Avoid `Read-Host` in scripts — accept all input via parameters.

```powershell
function Remove-UserAccount {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
        [Parameter()]
        [switch]$Force
    )
    begin { $ErrorActionPreference = 'Stop' }
    process {
        try {
            if ($Force -or $PSCmdlet.ShouldProcess($Username, "Remove $Username")) {
                Remove-ADUser -Identity $Username -ErrorAction Stop
            }
        } catch {
            $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
                $_.Exception, 'UnexpectedError', [System.Management.Automation.ErrorCategory]::NotSpecified, $Username
            ))
        }
    }
}
```

## Documentation and Style

- Include comment-based help for all public functions: `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.OUTPUTS`, `.NOTES`.
- 4-space indentation; opening braces on the same line; closing braces on a new line.
- Use full cmdlet names: `Where-Object` not `?`, `ForEach-Object` not `%`, `Get-ChildItem` not `ls`/`dir`.
- Line breaks after pipeline operators for readability.

## Validation

- [ ] All functions use `[CmdletBinding()]` where appropriate
- [ ] Parameters use `[switch]` for booleans, `ValidateSet` for constrained values
- [ ] Pipeline-supporting functions implement `Begin`/`Process`/`End`
- [ ] No aliases (`?`, `%`, `ls`, `gci`, etc.) in script code
- [ ] Comment-based help on all public-facing functions
- [ ] Destructive operations use `SupportsShouldProcess`
