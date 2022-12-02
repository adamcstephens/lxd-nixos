{
  description = "Let's focus on LXD and Nix together.";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-2205.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-2211.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit self;} {
      systems = ["x86_64-linux"];

      imports = [
        ./images.nix
        ./importer.nix
      ];

      perSystem = {
        pkgs,
        system,
        self',
        ...
      }: {
        devShells.default = pkgs.mkShellNoCC {
          buildInputs = [
            pkgs.cachix
            pkgs.just
            pkgs.lxd
          ];
        };
        packages = (self.imageImporters self) // {inherit (pkgs.callPackage ./packages/lxd.nix {}) lxd lxd_lts;};
      };
    }
    // {
      nixosModules.agent = import ./modules/agent.nix;
      nixosModules.container = import ./modules/container.nix;
      nixosModules.imageMetadata = import ./modules/image-metadata.nix;
      nixosModules.vm = import ./modules/vm.nix;
    };
}
