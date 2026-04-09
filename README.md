# Windows Dotfiles

Personal Windows development environment managed with a **bare git repository**,
so config files live at their real locations under `$HOME` without any symlinks.

## Structure

```
~/
├── .config/
│   ├── nvim/               # Neovim config (git submodule)
│   ├── wezterm/            # WezTerm terminal config (git submodule)
│   ├── vscode-nvim/        # VSCode Neovim extension keybindings
│   ├── visual-studio/      # Visual Studio exported settings
│   └── ssms/               # SQL Server Management Studio settings
├── .pwsh/
│   └── profile.ps1         # PowerShell profile
├── .starship/
│   └── starship.toml       # Starship prompt config
├── .vimrc                  # Vim config
├── .dotfiles-repo          # Memory file: SSH URL of your dotfiles remote
├── installer/
│   ├── bootstrap.ps1       # One-time new-machine setup  ← start here
│   ├── install.ps1         # Interactive TUI package installer
│   ├── cleanup.ps1         # Interactive system cleanup
│   ├── lib/
│   │   └── tui.ps1         # Shared TUI helpers (dot-sourced by all scripts)
│   ├── packages/
│   │   ├── scoop.txt       # Scoop package list
│   │   └── winget.txt      # Winget package IDs
│   └── fonts/              # Font files (installed by install.ps1)
├── dotfiles.ps1            # Sync helper (stage → commit → push)
└── README.md
```

## The `dot` Command

All dotfiles are managed via a bare git repository at `~/.dotfiles`.
The `dot` alias wraps `git` with the correct flags:

```powershell
function Invoke-Dot {
    git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" @Args
}
New-Alias dot Invoke-Dot
```

Use it exactly like `git`:

```powershell
dot status
dot add .config/nvim
dot commit -m "update nvim config"
dot push origin main
```

> The alias is defined in `~/.pwsh/profile.ps1` and loaded automatically.

---

## Setting Up a New Machine

### Option A — Bootstrap script (recommended)

```powershell
# Download and run directly:
irm https://raw.githubusercontent.com/gin31259461/dotfiles-win/main/installer/bootstrap.ps1 | iex

# Or clone first and run locally:
.\installer\bootstrap.ps1
```

Flags:
- `-Yes` — non-interactive, accept all defaults
- `-Repo <url>` — SSH URL of your fork (`user/repo` shorthand accepted)

What it does: checks prerequisites → clones repo → deploys files to `$HOME` →
configures git → inits submodules → optional `install.ps1`.

### Option B — Manual

```powershell
git clone --separate-git-dir="$HOME/.dotfiles" `
    git@github.com:gin31259461/dotfiles-win.git `
    "$env:TEMP\dotfiles-tmp"

robocopy "$env:TEMP\dotfiles-tmp" $HOME /E /XD .git | Out-Null
Remove-Item "$env:TEMP\dotfiles-tmp" -Recurse -Force

git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
```

### Install packages

```powershell
.\installer\install.ps1
```

The interactive TUI lets you toggle which packages and features to install
before anything touches your system.

---

## Syncing Dotfiles

`dotfiles.ps1` stages every tracked path, commits, and pushes in one shot.

```powershell
.\dotfiles.ps1                              # interactive commit message prompt
.\dotfiles.ps1 -Message "update config"    # skip prompt, use provided message
.\dotfiles.ps1 -DryRun                     # preview without committing
```

When `-Message` is omitted, a `Read-Host` prompt opens. Leave it empty to
fall back to `"sync dotfiles"`.

---

## Fork Owner Workflow

`.dotfiles-repo` stores the SSH URL for your machine's dotfiles remote.
This file is tracked and deployed to every new machine, so `bootstrap.ps1`
knows which fork to clone without any flags.

**First time (setting up your fork):**
```powershell
.\installer\bootstrap.ps1 -Repo 'git@github.com:you/dotfiles-win.git'
```
This clones the default repo as a base, sets your SSH URL as `origin`, bakes
your URL into the deployed `bootstrap.ps1`, and writes `~/.dotfiles-repo`.

**Commit and push your fork:**
```powershell
.\dotfiles.ps1 -Message "chore: set fork remote"
```

**All subsequent machines — no `-Repo` needed:**
```powershell
irm https://raw.githubusercontent.com/you/dotfiles-win/main/installer/bootstrap.ps1 | iex
```

---

## Cleanup

Free disk space interactively:

```powershell
.\installer\cleanup.ps1              # select tasks from a numbered list
.\installer\cleanup.ps1 -Unattended  # skip confirmations, run everything
```

Tasks: Scoop cache · Temp folder · npm cache · WinGet cache · Recycle Bin · thumbnail cache

---

## Submodules

| Submodule | Path | Repository |
|-----------|------|------------|
| nvchad | `.config/nvim` | `git@github.com:gin31259461/nvchad.git` |
| wezterm | `.config/wezterm` | `git@github.com:gin31259461/wezterm.git` |

After bootstrapping, initialise submodules:

```powershell
dot submodule update --init --recursive
```

---

## First Time Setup (from scratch)

Steps for creating this repo on a new machine.

### 1. Create the bare repository

```powershell
git init --bare $HOME/.dotfiles
```

### 2. Bootstrap the profile

Paste the snippet below into a temporary PowerShell session so you can use `dot`:

```powershell
function Invoke-Dot { git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" @Args }
New-Alias dot Invoke-Dot
```

### 3. Add a remote and configure

```powershell
dot remote add origin git@github.com:your-username/dotfiles-win.git
dot branch -m main
dot config --local status.showUntrackedFiles no
```

### 4. Track files and push

```powershell
dot add README.md dotfiles.ps1 installer .pwsh .starship .vimrc .config/nvim
dot commit -m "initial dotfiles"
dot push -u origin main
```

---

## References

- [A simpler way to manage your dotfiles](https://www.anand-iyer.com/blog/2018/a-simpler-way-to-manage-your-dotfiles/)
