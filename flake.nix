{
  description = "Let's focus on LXD and Nix together.";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-2211.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-linux" "x86_64-linux"];

      imports = [
        ./images.nix

        ./parts/devshell.nix
        ./parts/images.nix
        ./parts/packages.nix
      ];

      flake.nixosModules.agent = import ./modules/agent.nix;
      flake.nixosModules.container = import ./modules/container.nix;
      flake.nixosModules.imageMetadata = import ./modules/image-metadata.nix;
      flake.nixosModules.server = import ./modules/server.nix;
      flake.nixosModules.virtual-machine = import ./modules/virtual-machine.nix;

      flake.flakeModules.images = ./parts/images.nix;
    };
}
