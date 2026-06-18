# Windows Dotfiles

Personal Windows dotfiles managed with a bare Git repository at
`~/.dotfiles`. Files stay in their normal locations under `$HOME`, while Git
metadata stays outside the working tree.

## Layout

```text
~/
├── .config/
│   ├── nvim/             # Neovim config, submodule
│   ├── wezterm/          # WezTerm config, submodule
│   ├── vscode-nvim/      # VSCode Neovim settings
│   ├── visual-studio/    # Visual Studio settings
│   └── ssms/             # SQL Server Management Studio settings
├── .pwsh/profile.ps1     # PowerShell profile
├── .starship/starship.toml
├── .vimrc
├── .dotfiles-repo        # SSH URL used by bootstrap.ps1
├── installer/
│   ├── bootstrap.ps1     # New-machine setup
│   ├── install.ps1       # Interactive package installer
│   ├── cleanup.ps1       # Interactive cleanup tool
│   ├── lib/              # Shared script helpers
│   ├── packages/         # Scoop and WinGet package lists
│   └── fonts/            # Fonts installed by install.ps1
├── dotfiles.ps1          # Stage, commit, and push helper
└── README.md
```

## Dot Command

The PowerShell profile defines a `dot` alias for the bare repository:

```powershell
function Invoke-Dot {
    git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" @Args
}
New-Alias dot Invoke-Dot
```

Use `dot` the same way you use `git`:

```powershell
dot status
dot add .config/nvim
dot commit -m "update nvim config"
dot push origin main
```

## New Machine Setup

Download and run the bootstrap script:

```powershell
$Bootstrap = "https://github.com/gin31259461/dotfiles-win" +
    "/raw/main/installer/bootstrap.ps1"
irm $Bootstrap -OutFile bootstrap.ps1
.\bootstrap.ps1
```

Useful flags:

- `-Yes`: accept defaults without prompts.
- `-Repo <url>`: clone from a fork or another SSH remote.

The bootstrap script checks prerequisites, clones the bare repository, deploys
files to `$HOME`, configures Git, initializes submodules, and can launch the
package installer.

## Manual Setup

```powershell
git clone --separate-git-dir="$HOME/.dotfiles" `
    git@github.com:gin31259461/dotfiles-win.git `
    "$env:TEMP\dotfiles-tmp"

robocopy "$env:TEMP\dotfiles-tmp" $HOME /E /XD .git | Out-Null
Remove-Item "$env:TEMP\dotfiles-tmp" -Recurse -Force

git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" `
    config --local status.showUntrackedFiles no
```

## Packages

Package lists are plain text files:

- `installer/packages/scoop.txt`
- `installer/packages/winget.txt`

Blank lines and lines starting with `#` are ignored. Run the installer when you
want to install or update selected packages:

```powershell
.\installer\install.ps1
```

## Syncing Changes

Use `dotfiles.ps1` to stage tracked paths, commit, and push:

```powershell
.\dotfiles.ps1
.\dotfiles.ps1 -Message "update config"
.\dotfiles.ps1 -DryRun
```

If `-Message` is omitted, the script prompts for one. An empty message falls
back to `sync dotfiles`.

## Fork Workflow

Store your fork remote during bootstrap:

```powershell
.\installer\bootstrap.ps1 -Repo 'git@github.com:you/dotfiles-win.git'
```

The script writes the remote to `~/.dotfiles-repo` so future machines can use
your fork without passing `-Repo` again. Commit the updated file and script:

```powershell
.\dotfiles.ps1 -Message "chore: set fork remote"
```

## Cleanup

Run the cleanup tool when you want to clear caches and temporary files:

```powershell
.\installer\cleanup.ps1
.\installer\cleanup.ps1 -Unattended
```

Cleanup covers Scoop, npm, WinGet, temporary files, the Recycle Bin, and the
thumbnail cache.

## Submodules

| Name | Path | Repository |
| --- | --- | --- |
| nvchad-config | `.config/nvim` | `git@github.com:gin31259461/nvchad.git` |
| wezterm | `.config/wezterm` | `git@github.com:gin31259461/wezterm.git` |

Initialize or refresh submodules with:

```powershell
dot submodule update --init --recursive
```

## Reference

- [A simpler way to manage your dotfiles](https://www.anand-iyer.com/blog/2018/a-simpler-way-to-manage-your-dotfiles/)
