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

      imports = [
        ./images.nix
      ];

      perSystem = {
        pkgs,
        system,
        self',
        ...
      }:
      # self.lib.genWithNixpkgs {
      #   inherit self' system;
      #   pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
      #   release = "unstable";
      # }
      # // self.lib.genWithNixpkgs {
      #   inherit self' system;
      #   pkgs = inputs.nixpkgs-2205.legacyPackages.${system};
      #   release = "22.05";
      # }
      # //
      {
        _module.args.pkgs = inputs.nixpkgs-2205.legacyPackages.${system};

        devShells.default = pkgs.mkShellNoCC {
          buildInputs = [
            pkgs.cachix
            pkgs.just
            pkgs.lxd
          ];
        };
      };
    }
    // {
      # lib.genWithNixpkgs = {
      #   pkgs,
      #   release,
      #   system,
      #   self',
      # }: let
      #   releaseString = "nixpkgs-${release}";
      #   releaseVM = "${releaseString}-image-vm";
      #   releaseContainer = "${releaseString}-image-container";
      #   importerVM = "import-${releaseString}-image-vm";
      #   importerContainer = "import-${releaseString}-image-container";
      # in {
      #   _module.args.pkgs = pkgs;

      #   checks.${releaseContainer} = import ./nixos-test.nix {
      #     inherit pkgs;
      #     makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");

      #     testName = "lxd-container-test";
      #     importer = self'.packages.${importerContainer};
      #     release = self.nixosConfigurations.image-container.config.system.nixos.release;
      #   };

      #   checks.${releaseVM} = import ./nixos-test.nix {
      #     inherit pkgs;
      #     makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");

      #     testName = "lxd-vm-test";
      #     importer = self'.packages.${importerVM};
      #     release = self.nixosConfigurations.image-vm.config.system.nixos.release;
      #     vm = true;
      #   };

      #   packages = rec {
      #     ${releaseVM} = pkgs.symlinkJoin {
      #       name = "${releaseVM}";
      #       paths = [
      #         self.nixosConfigurations.image-vm.config.system.build.qemuImage
      #         self.nixosConfigurations.image-vm.config.system.build.metadata
      #       ];
      #     };
      #     ${importerVM} = pkgs.writeScriptBin "import-image" ''
      #       IMAGE="${releaseVM}"

      #       echo "Importing VM image $IMAGE"
      #       lxc image import --alias nixos/${self.nixosConfigurations.${releaseVM}.config.system.nixos.release} \
      #         $IMAGE/tarball/nixos-lxd-metadata-${system}.tar.xz \
      #         $IMAGE/nixos.qcow2
      #     '';

      #     ${releaseContainer} = pkgs.symlinkJoin {
      #       name = "${releaseContainer}";
      #       paths = [
      #         self.nixosConfigurations.image-container.config.system.build.tarball
      #         self.nixosConfigurations.image-container.config.system.build.metadata
      #       ];
      #     };
      #     ${importerContainer} = pkgs.writeScriptBin "import-image" ''
      #       IMAGE="${releaseContainer}"

      #       echo "Importing container image $IMAGE"
      #       lxc image import --alias nixos/${self.nixosConfigurations.image-container.config.system.nixos.release} \
      #         $IMAGE/tarball/nixos-lxd-metadata-${system}.tar.xz \
      #         $IMAGE/tarball/nixos-lxd-image-${system}.tar.xz
      #     '';
      #   };
      # };

      nixosModules.agent = import ./modules/agent.nix;
      nixosModules.container = import ./modules/container.nix;
      nixosModules.imageMetadata = import ./modules/image-metadata.nix;
      nixosModules.vm = import ./modules/vm.nix;

      # nixosConfigurations.image-vm = inputs.nixpkgs-unstable.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     self.nixosModules.vm
      #     self.nixosModules.image-metadata
      #     {
      #       system.stateVersion = "22.05";
      #     }
      #   ];
      # };
      # nixosConfigurations.image-container = inputs.nixpkgs-unstable.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     self.nixosModules.container
      #     self.nixosModules.image-metadata
      #     {
      #       system.stateVersion = "22.05";
      #     }
      #   ];
      # };
    };
}
