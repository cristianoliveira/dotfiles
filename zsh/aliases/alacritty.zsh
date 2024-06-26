export TERMINAL_TRANSPARENCY=0.94
if [ "$(uname)" = "Darwin" ]; then
  alias terminal-trasparent-off="sed -i 's/opacity = $TERMINAL_TRANSPARENCY/opacity = 1/g' ~/.config/alacritty/alacritty.toml"
  alias terminal-trasparent-on="sed -i 's/opacity = 1/opacity = $TERMINAL_TRANSPARENCY/g' ~/.config/alacritty/alacritty.toml"
else
  alias terminal-trasparent-off="sed 's/opacity = $TERMINAL_TRANSPARENCY/opacity = 1/g' ~/.config/alacritty/alacritty.yml"
  alias terminal-trasparent-on="sed 's/opacity = 1/opacity = $TERMINAL_TRANSPARENCY/g' ~/.config/alacritty/alacritty.yml"
fi
