# Run nix home-manager
setup-nix: remove-zsh install clean

# Install packages by nix home-manager
install:
    home-manager switch --flake .#limjihoon

# Clean redundant packages by nix gc
clean:
		nix-collect-garbage -d

# Remove zsh
remove-zsh:
  rm -rf ~/.zshrc
  sudo apt-get --purge remove zsh 
