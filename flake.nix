{
  description = "Let's focus on LXD and Nix together.";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-2305.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-qemu.url = "github:nixos/nixpkgs/3c384353a64ee069240af601aa6781bb556351cf";
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
      flake.flakeModules.baseImages = ./images.nix;
    };
}
