{
  description = "Let's focus on LXD and Nix together.";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs-2205";
    nixpkgs-2205.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit self;} {
      systems = ["x86_64-linux"];

      perSystem = {
        pkgs,
        system,
        ...
      }: {
        _module.args.pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};

        devShells.default = pkgs.mkShellNoCC {
          buildInputs = [
            pkgs.cachix
            pkgs.just
            pkgs.lxd
          ];
        };

        packages = rec {
          image-vm = pkgs.symlinkJoin {
            name = "image-vm";
            paths = [
              self.nixosConfigurations.image-vm.config.system.build.qemuImage
              self.nixosConfigurations.image-vm.config.system.build.metadata
            ];
          };
          import-image-vm = pkgs.writeScriptBin "import-image-vm" ''
            IMAGE="${image-vm}"

            echo "Importing VM image $IMAGE"
            lxc image import --alias nixos/22.05 \
              $IMAGE/tarball/nixos-lxd-metadata-x86_64-linux.tar.xz \
              $IMAGE/nixos.qcow2
          '';

          image-container = pkgs.symlinkJoin {
            name = "image-container";
            paths = [
              self.nixosConfigurations.image-container.config.system.build.tarball
              self.nixosConfigurations.image-container.config.system.build.metadata
            ];
          };
          import-image-container = pkgs.writeScriptBin "import-image-container" ''
            IMAGE="${image-container}"

            echo "Importing container image $IMAGE"
            lxc image import --alias nixos/22.05 \
              $IMAGE/tarball/nixos-lxd-metadata-x86_64-linux.tar.xz \
              $IMAGE/tarball/nixos-lxd-image-x86_64-linux.tar.xz
          '';

          image-container-aarch64-linux = pkgs.symlinkJoin {
            name = "image-container";
            paths = [
              self.nixosConfigurations.image-container-aarch64-linux.config.system.build.tarball
              self.nixosConfigurations.image-container-aarch64-linux.config.system.build.metadata
            ];
          };
        };
      };
    }
    // {
      nixosModules.agent = import ./modules/agent.nix;
      nixosModules.container = import ./modules/container.nix;
      nixosModules.image-metadata = import ./modules/image-metadata.nix;
      nixosModules.vm = import ./modules/vm.nix;

      flake.nixosConfigurations.image-vm = inputs.nixpkgs-unstable.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.vm
          self.nixosModules.image-metadata
          {
            system.stateVersion = "22.05";
          }
        ];
      };
      flake.nixosConfigurations.image-container = inputs.nixpkgs-unstable.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.container
          self.nixosModules.image-metadata
          {
            system.stateVersion = "22.05";
          }
        ];
      };
    };
}
