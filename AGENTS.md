# Windows Dotfiles

Bare git repo, used for managing dotfiles in $HOME with a separate git directory at ~/.dotfiles/.

```bash
New-Alias -Name dot -Value Invoke-Dot -ErrorAction SilentlyContinue

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
```

## Scripts

- ~/.pwsh/profile.ps1: PowerShell profile (symlinked to `$profile`)
- ~/installer: bootstrap.ps1, install.ps1, cleanup.ps1, lib/, packages/, fonts/
- ~/dotfiles.ps1: Sync helper: stage → commit → push

## Package Lists

- installer/packages/scoop.txt (one per line)
- installer/packages/winget.txt (one ID per line)
- `#` lines ignored

## File Encoding

All .ps1 files must be UTF-8 with BOM (PowerShell 5.1 requirement). Create: `[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($true))`.

Verify: check first 3 bytes are `EF BB BF`.

Re-write with BOM if missing after editing.

## Commit Rules

- Structure: header, body (optional), footer (optional).

    ```plain
    type(scope): subject -> header

    - content -> body
    - content
    - content

    footer
    ```

- Rules:
  - header is brief, 50 chars or less, imperative mood, no period at end
  - body 72 chars wrapped, optional
  - footer for co-authors, references, etc., optional (this project not allow co-authors trailers)
  - do not add any co-authors trailers

- Types:
  - feat: new feature
  - fix: bug fix
  - docs: documentation only changes
  - style: code formatting, no logic changes
  - refactor: code refactoring
  - perf: performance improvement
  - test: test changes
  - build: build system changes
  - ci: CI configuration changes
  - chore: other changes
