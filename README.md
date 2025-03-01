# Dotfiles for Windows

## First Time Setup

1. create bare repository

   ```pwsh
   mkdir $HOME/.dotfiles

   git init --bare $HOME/.dotfiles
   ```

2. make an alias for runing git commands (to powershell profile setting)

   ```pwsh
    New-Alias dot git-dot

    function git-dot {
        git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME @Args
    }
   ```

3. add a remote, and also set status not to show untracked files

   ```pwsh
   dot config --local status.showUntrackedFiles no

   dot remote add origin git@github.com:gin31259461/dotfiles-win.git

   dot branch -m main
   ```

4. run `dotfiles.ps1` to sync dotfiles automatically

## Setting up a new machine

1. install [pwsh-setup](https://github.com/gin31259461/pwsh-setup) for setup powershell

2. after open new terminal, run following command

```pwsh
git clone --separate-git-dir=$HOME/.dotfiles \
  git@github.com:gin31259461/dotfiles-win.git tmpdotfiles

robocopy tmpdotfiles $HOME /E /V /XD .git

Remove-Item -Path "tmpdotfiles" -Recurse -Force

dot config --local status.showUntrackedFiles no
```

## TODO

- automated setup script for new machine

## References

- [A simpler way to manage your dotfiles](https://www.anand-iyer.com/blog/2018/a-simpler-way-to-manage-your-dotfiles/)
