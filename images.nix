{
  withSystem,
  inputs,
  self,
  ...
}: let
  mkImageRelease = {
    pkgs,
    system,
    releaseName,
  }:
    pkgs.symlinkJoin {
      name = releaseName;
      paths = [
        self.nixosConfigurations.${releaseName}.config.system.build.tarball
        self.nixosConfigurations.${releaseName}.config.system.build.metadata
      ];
    };

  mkImageImporter = {
    pkgs,
    system,
    releaseName,
    imageRelease,
  }: let
    pkg = self.packages.${system}.${releaseName};
  in
    pkgs.writeScriptBin "import-image" ''
      echo "Importing container image ${pkg}"
      lxc image import --alias nixos/${imageRelease} \
        ${pkg}/tarball/nixos-lxd-metadata-${system}.tar.xz \
        ${pkg}/tarball/nixos-lxd-image-${system}.tar.xz
    '';

  mkImageTest = {
    pkgs,
    importerName,
    releaseName,
    system,
  }:
    import ./nixos-test.nix {
      inherit pkgs;
      makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");

      testName = "${releaseName}-test";
      importer = self.packages.${system}.${importerName};
      release = releaseName;
    };

  mkImage = {
    type,
    nixosRelease,
    # self',
    system,
  }: let
    normalizeRelease = builtins.replaceStrings ["."] [""] nixosRelease;
    releaseSystem = builtins.replaceStrings ["-linux"] [""] system;
    releaseName = "image_${type}_${normalizeRelease}";
    imageRelease = "nixos/${nixosRelease}";
    importerName = "importer_${releaseName}";
    inputNixpkgsRelease = "nixpkgs-" + normalizeRelease;
    pkgs = inputs.${inputNixpkgsRelease}.legacyPackages.${system};
  in rec {
    flake.checks.${system}.${releaseName} = import ./nixos-test.nix {
      inherit pkgs;
      makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");

      testName = "${releaseName}-test";
      importer = self.packages.${system}.${importerName};
      release = releaseName;
    };

    flake.nixosConfigurations.${releaseName} = withSystem system ({...}:
      inputs.${inputNixpkgsRelease}.lib.nixosSystem {
        system = system;
        modules = [
          self.nixosModules.${type}
          self.nixosModules.imageMetadata
          {
            system.stateVersion = nixosRelease;
          }
        ];
      });

    flake.packages.${system} = {
      ${releaseName} = pkgs.symlinkJoin {
        name = releaseName;
        paths = [
          self.nixosConfigurations.${releaseName}.config.system.build.tarball
          self.nixosConfigurations.${releaseName}.config.system.build.metadata
        ];
      };
      ${importerName} = let
        pkg = self.packages.${system}.${releaseName};
      in
        pkgs.writeScriptBin "import-image" ''
          echo "Importing container image ${pkg}"
          lxc image import --alias nixos/${imageRelease} \
            ${pkg}/tarball/nixos-lxd-metadata-${system}.tar.xz \
            ${pkg}/tarball/nixos-lxd-image-${system}.tar.xz
        '';
    };
  };
in
  # inputs.nixpkgs-2205.lib.recursiveUpdate mkImage {
  #   system = "aarch64-linux";
  #   type = "container";
  #   nixosRelease = "22.05";
  # }
  mkImage {
    system = "x86_64-linux";
    type = "container";
    nixosRelease = "22.05";
  }
