# List all the just commands
default:
	@just --list

regen-cargo-nix:
	rm -f Cargo.nix
	nix run nixpkgs#crate2nix -- generate

