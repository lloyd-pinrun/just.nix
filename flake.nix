{
  description = "Integration of just command runner with Nix";

  inputs = {
    # -- Essentials --
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # -- Development --
    pre-commit.url = "github:cachix/git-hooks.nix";
  };

  outputs = inputs @ {
    flake-parts,
    systems,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.pre-commit.flakeModule
        ./default.nix
      ];

      systems = [
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      flake.flakeModule = ./flake-module.nix;
    };
}
