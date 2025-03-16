# Install packages by nix home-manager
install:
    home-manager switch --flake .#limjihoon

# Enable jenkins
jenkins:
    home-manager services.jenkins.enable = true;

# Clean redundant packages by nix gc
clean:
		nix-collect-garbage -d
