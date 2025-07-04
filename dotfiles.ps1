cd $HOME

dot add README.md .gitmodules dotfiles.ps1 
dot add .config/wezterm
dot add .config/visual-studio
dot add .config/vscode-nvim
dot add .config/ssms
dot add .config/nvim
dot add .vimrc
dot add ./AppData/Roaming/alacritty/


# push
dot commit -m "sync dotfiles"
dot push origin main
