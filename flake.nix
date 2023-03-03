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
      systems = ["x86_64-linux"];

      imports = [
        ./images.nix
        ./importer.nix
      ];

      perSystem = {
        inputs',
        pkgs,
        system,
        self',
        ...
      }: let
        lxdOverrides = {
          OVMFFull = self'.packages.ovmf;
          btrfs-progs = pkgs.btrfs-progs.overrideAttrs (old: rec {
            version = "6.0";
            src = pkgs.fetchurl {
              url = "mirror://kernel/linux/kernel/people/kdave/btrfs-progs/btrfs-progs-v${version}.tar.xz";
              sha256 = "sha256-Rp4bLshCpuZISK5j3jAiRG+ACel19765GRkfE3y91TQ=";
            };
          });
          libnvidia-container = inputs'.nixpkgs-unstable.legacyPackages.callPackage "${inputs.nixpkgs-unstable.outPath}/pkgs/applications/virtualization/libnvidia-container" {};
        };
      in {
        devShells.default = pkgs.mkShellNoCC {
          buildInputs = [
            pkgs.cachix
            pkgs.just
            # self'.packages.lxd-latest.client
          ];
        };

        packages =
          (self.imageImporters self)
          // {
            inherit
              (pkgs.callPackage ./packages/lxd {
                inherit (inputs'.nixpkgs-unstable.legacyPackages) dqlite raft-canonical;
              })
              lxd-unwrapped-lts
              lxd-unwrapped
              ;

            ovmf = pkgs.callPackage ./packages/ovmf {};

            lxd = pkgs.callPackage ./packages/lxd/wrapper.nix {
              inherit (lxdOverrides) OVMFFull libnvidia-container;
              lxd-unwrapped = self'.packages.lxd-unwrapped;
            };

            lxd-lts = pkgs.callPackage ./packages/lxd/wrapper.nix {
              inherit (lxdOverrides) OVMFFull btrfs-progs libnvidia-container;
              lxd-unwrapped = self'.packages.lxd-unwrapped-lts;
            };
          };
      };
    }
    // {
      nixosModules.agent = import ./modules/agent.nix;
      nixosModules.container = import ./modules/container.nix;
      nixosModules.imageMetadata = import ./modules/image-metadata.nix;
      nixosModules.vm = import ./modules/vm.nix;
    };
}
