cd $HOME

dot add README.md dotfiles.ps1 
dot add .config/wezterm
dot add .config/visual-studio
dot add .vimrc

# push
dot commit -m "sync dotfiles"
dot push origin main
