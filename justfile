# Install packages by nix home-manager
install:
    home-manager switch --flake .#limjihoon

# Clean redundant packages by nix gc
clean:
		nix-collect-garbage -d
