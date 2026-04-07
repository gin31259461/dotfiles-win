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
├── installer/
│   ├── Install.ps1         # Interactive TUI installer ← start here
│   ├── Bootstrap.ps1       # One-time new-machine setup
│   ├── packages/
│   │   ├── scoop.txt       # Scoop package list
│   │   └── winget.txt      # Winget package IDs
│   └── fonts/              # Font files (installed by Install.ps1)
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

## First Time Setup

Steps for creating this repo from scratch on a new machine.

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

### 5. Syncing going forward

```powershell
.\dotfiles.ps1                            # sync with default message
.\dotfiles.ps1 -Message "update config"  # custom commit message
.\dotfiles.ps1 -DryRun                   # preview without committing
```

---

## Setting Up a New Machine

### Option A — Bootstrap script (recommended)

```powershell
# Clone this repo somewhere, then:
.\installer\Bootstrap.ps1
```

Or with a custom URL:

```powershell
.\installer\Bootstrap.ps1 -RepoUrl 'https://github.com/your-username/dotfiles-win.git'
```

### Option B — Manual

```powershell
git clone --separate-git-dir="$HOME/.dotfiles" `
    git@github.com:your-username/dotfiles-win.git `
    "$env:TEMP\dotfiles-tmp"

robocopy "$env:TEMP\dotfiles-tmp" $HOME /E /XD .git | Out-Null
Remove-Item "$env:TEMP\dotfiles-tmp" -Recurse -Force

git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
```

### Run the installer

```powershell
.\installer\Install.ps1
```

The interactive TUI lets you toggle which packages and features to install
before anything touches your system.

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

## References

- [A simpler way to manage your dotfiles](https://www.anand-iyer.com/blog/2018/a-simpler-way-to-manage-your-dotfiles/)
