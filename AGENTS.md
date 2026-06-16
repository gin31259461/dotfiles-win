# Windows Dotfiles

Bare git repo, working tree is `$HOME`, bare repo at `~/.dotfiles/`.

```bash
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

## Rules

- Use `dot` instead of `git` in `$HOME`
- `dot status` hides untracked files by design
- Commit always without co-author trailers

## Scripts

- ~/.pwsh/profile.ps1: PowerShell profile (symlinked to `$profile`)
- ~/installer: bootstrap.ps1, install.ps1, cleanup.ps1, lib/, packages/, fonts/
- ~/dotfiles.ps1: Sync helper: stage → commit → push

## Package Lists

- `installer/packages/scoop.txt` (one per line)
- `installer/packages/winget.txt` (one ID per line)
- `#` lines ignored

## File Encoding

All `.ps1` files **must** be UTF-8 with BOM (PowerShell 5.1 requirement). Create: `[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($true))`. Verify: check first 3 bytes are `EF BB BF`. Re-write with BOM if missing after editing.

## Commit Convention

Structure: Header, optional Body, optional Footer.

```plain
<type>(<scope>): <subject>

<body>

<footer>
```

Rules:

- Header is brief, 50 chars or less, imperative mood, no period at end
- Body 72 chars wrapped, optional
- Footer for co-authors, references, etc., optional (this project not allow co-authors trailers)

Types:

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
