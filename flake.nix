{
  description = "Rust-Nix";

  inputs = {
    flake-parts = {
      url = "github:hercules-ci/flake-parts/9d0d87172c374f89da73c1cfe6d81ae62feac1f1";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    rust-overlay.url = "github:oxalica/rust-overlay/996e9b0b019a4a9eb9e9a5641aefa06d801b5895";
    crate2nix.url = "github:nix-community/crate2nix/0.15.0";

    # Development

    devshell = {
      url = "github:numtide/devshell/255a2b1725a20d060f566e4755dbf571bbbb5f76";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    # NOTE: enable for IFD and cache optimization
    ##extra-trusted-public-keys = "eigenvalue.cachix.org-1:ykerQDDa55PGxU25CETy9wF6uVDpadGGXYrFNJA3TUs=";
    ##extra-substituters = "https://eigenvalue.cachix.org";
    ##allow-import-from-derivation = true;
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      rust-overlay,
      crate2nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [
        ./nix/rust-overlay/flake-module.nix
        ./nix/devshell/flake-module.nix
      ];

      perSystem =
        {
          system,
          pkgs,
          lib,
          inputs',
          ...
        }:
        let
          # If you dislike IFD, you can also generate it with `crate2nix generate`
          # on each dependency change and import it here with `import ./Cargo.nix`.
          ##cargoNix = inputs.crate2nix.tools.${system}.appliedCargoNix {
          ##  name = "rustnix";
          ##  src = ./.;
          ##};

          cargoNix = import ./Cargo.nix { inherit pkgs; };
        in
        rec {
          checks = {
            rustnix = cargoNix.rootCrate.build.override {
              runTests = true;
            };
          };

          packages = {
            rustnix = cargoNix.rootCrate.build;
            default = packages.rustnix;

            inherit (pkgs) rust-toolchain;

            rust-toolchain-versions = pkgs.writeScriptBin "rust-toolchain-versions" ''
              ${pkgs.rust-toolchain}/bin/cargo --version
              ${pkgs.rust-toolchain}/bin/rustc --version
            '';
          };
        };
    };
}
