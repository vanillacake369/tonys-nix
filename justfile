# Run nix home-manager
setup-nix: install-uidmap install clean
# setup-nix: remove-nvim remove-spacevim remove-zsh install-uidmap install clean apply-zsh


# Enable uidmap
install-uidmap:
  which newuidmap newgidmap || sudo apt update && sudo apt install -y uidmap

# Clear all dependencies
clear-all:
  echo y | home-manager uninstall

# Remove nvim
remove-nvim:
  rm -rf ~/.config/nvim
  rm -rf ~/.local/share/nvim
  rm -rf ~/.cache/nvim

# Remove spacevim
remove-spacevim:
  rm -rf ~/.nix-profile/bin/spacevim
  rm -rf ~/.SpaceVim*
  
# Remove zsh
remove-zsh:
  rm -rf ~/.zshrc
  sudo apt-get --purge remove zsh 

# Install packages by nix home-manager
install:
  home-manager switch --flake .#limjihoon -b back

# Clean redundant packages by nix gc
clean:
  nix-collect-garbage -d

# Apply zsh
apply-zsh:
  exec zsh
  chsh -s /home/limjihoon/.nix-profile/bin/zsh
