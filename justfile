# List all the just commands
default:
	@just --list

regen-cargo-nix:
	rm Cargo.nix
	nix run nixpkgs#crate2nix -- generate

