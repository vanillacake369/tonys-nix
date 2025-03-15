# Tole to write in hand, do what I've told to do LOL
# Cp/Pst is easy but is poison when learning things
.PHONY: update
update:
		home-manager switch --flake .#limjihoon
.PHONY: clean
clean:
		nix-collect-garbage -d
