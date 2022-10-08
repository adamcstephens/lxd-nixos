{
  description = "Let's focus on LXD and Nix together.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
  };
  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
  in {
    devShells.x86_64-linux.default = pkgs.mkShellNoCC {
      buildInputs = [
        pkgs.cachix
        pkgs.just
        pkgs.lxd
      ];
    };
    nixosModules.agent = import ./modules/agent.nix;
    nixosModules.container = import ./modules/container.nix;
    nixosModules.image-metadata = import ./modules/image-metadata.nix;
    nixosModules.vm = import ./modules/vm.nix;

    nixosConfigurations.image-vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.vm
        self.nixosModules.image-metadata
        {
          system.stateVersion = "22.05";
        }
      ];
    };

    nixosConfigurations.image-container = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.container
        self.nixosModules.image-metadata
        {
          system.stateVersion = "22.05";
        }
      ];
    };

    nixosConfigurations.image-container-aarch64-linux = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        self.nixosModules.container
        self.nixosModules.image-metadata
        {
          system.stateVersion = "22.05";
        }
      ];
    };

    packages.x86_64-linux = rec {
      image-vm = pkgs.symlinkJoin {
        name = "image-vm";
        paths = [
          self.nixosConfigurations.image-vm.config.system.build.qemuImage
          self.nixosConfigurations.image-vm.config.system.build.metadata
        ];
      };
      import-image-vm = pkgs.writeScriptBin "import-image-vm" ''
        lxc image import --alias nixos/22.05 \
          ${image-vm}/tarball/nixos-lxd-metadata-x86_64-linux.tar.xz \
          ${image-vm}/nixos.qcow2
      '';

      image-container = pkgs.symlinkJoin {
        name = "image-container";
        paths = [
          self.nixosConfigurations.image-container.config.system.build.tarball
          self.nixosConfigurations.image-container.config.system.build.metadata
        ];
      };
      import-image-container = pkgs.writeScriptBin "import-image-container" ''
        lxc image import --alias nixos/22.05 \
          ${image-container}/tarball/nixos-lxd-metadata-x86_64-linux.tar.xz \
          ${image-container}/tarball/nixos-lxd-image-x86_64-linux.tar.xz
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
