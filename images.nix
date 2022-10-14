{
  withSystem,
  inputs,
  self,
  lib,
  ...
}: let
  mkImage = {
    type,
    nixosRelease,
    # self',
    system,
  }: let
    normalizeRelease = builtins.replaceStrings ["."] [""] nixosRelease;
    releaseName = "image-${type}-${normalizeRelease}";

    imageRelease = "nixos/${nixosRelease}";
    importerName = "import-${releaseName}";
    inputNixpkgsRelease = "nixpkgs-" + normalizeRelease;
    pkgs = inputs.${inputNixpkgsRelease}.legacyPackages.${system};
    vm =
      if type == "vm"
      then true
      else false;

    imagePath =
      if vm
      then "qemuImage"
      else "tarball";
    imagePkg = self.packages.${system}.${releaseName};
    imagePathFile =
      if vm
      then imagePkg + "/nixos.qcow2"
      else imagePkg + "/tarball/nixos-lxd-image-${system}.tar.xz";
  in {
    flake.checks.${system}.${releaseName} = import ./nixos-test.nix {
      inherit pkgs vm;
      makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");

      testName = "${releaseName}_test";
      importerBin = self.packages.${system}.${importerName} + "/bin/import-" + releaseName;
      image = imageRelease;
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
          self.nixosConfigurations.${releaseName}.config.system.build.${imagePath}
          self.nixosConfigurations.${releaseName}.config.system.build.metadata
        ];
      };

      ${importerName} = pkgs.writeScriptBin "import-${releaseName}" ''
        echo "Importing container image ${imagePkg}"
        lxc image import --alias ${imageRelease} \
          ${imagePkg}/tarball/nixos-lxd-metadata-${system}.tar.xz \
          ${imagePathFile}
      '';
    };
  };
in
  builtins.foldl' (l: r:
    lib.attrsets.recursiveUpdate l r) {} [
    (mkImage {
      system = "aarch64-linux";
      type = "container";
      nixosRelease = "22.05";
    })
    (mkImage {
      system = "x86_64-linux";
      type = "container";
      nixosRelease = "22.05";
    })
    (mkImage {
      system = "x86_64-linux";
      type = "container";
      nixosRelease = "unstable";
    })
    (mkImage {
      system = "x86_64-linux";
      type = "vm";
      nixosRelease = "22.05";
    })
    (mkImage {
      system = "x86_64-linux";
      type = "vm";
      nixosRelease = "unstable";
    })
  ]
