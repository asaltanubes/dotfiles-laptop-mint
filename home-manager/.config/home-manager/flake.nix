{
  description = "Home Manager configuration of asaltanubes";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cspell-lsp = {
      url = "github:asaltanubes/cspell-lsp";
      inputs.nixpkgs.follows = "nixpkgs";
      };
  };

  outputs =
    { nixpkgs, home-manager, cspell-lsp, ... }:
    let
      mkHome={extraArgs, system?"x86_64-linux"}: home-manager.lib.homeManagerConfiguration {
        pkgs=nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit cspell-lsp; } // extraArgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./home.nix ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    in
    {
      homeConfigurations."asaltanubes" = mkHome { };
      homeConfigurations."asaltanubes@asaltanubes-Lenovo-V15-G2-ALC" = mkHome { isMint = true; };
    };
}
