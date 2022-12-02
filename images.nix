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
    system,
    metadata ? {},
  }: let
    normalizeRelease = builtins.replaceStrings ["."] [""] nixosRelease;
    releaseName = "image-${type}-${normalizeRelease}";

    imageTag = metadata.imageName or "${nixosRelease}/${type}";
    imageRelease = "nixos/${imageTag}";

    importerName = "lxd-import-${releaseName}";

    inputNixpkgsRelease = "nixpkgs-" + normalizeRelease;
    pkgs = inputs.${inputNixpkgsRelease}.legacyPackages.${system};
  in {
    flake.checks.${system}.${releaseName} = import ./nixos-test.nix {
      inherit pkgs type;

      makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");
      testName = releaseName;

      importerBin = self.packages.${system}.${importerName} + "/bin/import";
      image = imageRelease;
    };

    flake.nixosConfigurations.${releaseName} = withSystem system ({...}:
      inputs.${inputNixpkgsRelease}.lib.nixosSystem {
        system = system;
        modules = [
          self.nixosModules.${type}
          {
            system.stateVersion = nixosRelease;

            _module.args.lxd = metadata;
          }
        ];
      });
  };
in
  builtins.foldl' (l: r:
    lib.attrsets.recursiveUpdate l r) {} [
    (mkImage {
      system = "aarch64-linux";
      type = "container";
      nixosRelease = "22.05";
      metadata.imageName = "22.05/container";
    })
    (mkImage {
      system = "x86_64-linux";
      type = "container";
      nixosRelease = "22.05";
      metadata.imageName = "22.05/container";
    })
    (mkImage {
      system = "x86_64-linux";
      type = "vm";
      nixosRelease = "22.05";
      metadata.imageName = "22.05/vm";
    })
    (mkImage {
      system = "x86_64-linux";
      type = "container";
      nixosRelease = "22.11";
      metadata.imageName = "22.11/container";
    })
    (mkImage {
      system = "x86_64-linux";
      type = "vm";
      nixosRelease = "22.11";
      metadata.imageName = "22.11/vm";
    })
    (mkImage {
      system = "x86_64-linux";
      type = "container";
      nixosRelease = "unstable";
      metadata.imageName = "unstable/container";
    })
    (mkImage {
      system = "x86_64-linux";
      type = "vm";
      nixosRelease = "unstable";
      metadata.imageName = "unstable/vm";
    })
  ]
