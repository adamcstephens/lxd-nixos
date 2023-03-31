{
  config,
  inputs,
  lib,
  self,
  withSystem,
  ...
}: let
  images = config.lxd.images;

  nixosConfigurations = lib.mapAttrs (_: i: i.nixosConfiguration) images;

  # group images into system-based sortings
  apps = lib.zipAttrs (builtins.attrValues (lib.mapAttrs (_: i: i.app) images));
  checks = lib.zipAttrs (builtins.attrValues (lib.mapAttrs (_: i: i.check) images));
in {
  options = {
    lxd.images = lib.mkOption {
      default = {};
      type = lib.types.attrsOf (lib.types.submodule ({
        name,
        config,
        ...
      }: {
        options = {
          system = lib.mkOption {
            type = lib.types.enum ["aarch64-linux" "x86_64-linux"];
            description = lib.mdDoc ''
              Image system. Used to generate nixosConfiguration, app, and check
            '';
          };

          type = lib.mkOption {
            type = lib.types.enum ["container" "virtual-machine"];
            description = lib.mdDoc ''
              Image type
            '';
          };

          nixpkgs = lib.mkOption {
            type = lib.types.unspecified;
            default = inputs.nixpkgs;
            description = lib.mdDoc ''
              nixpkgs input used for nixosConfiguration
            '';
          };

          metadata = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {};
            description = lib.mdDoc ''
              LXD metadata to pass through to image

            '';
          };

          release = lib.mkOption {
            type = lib.types.str;
            description = lib.mdDoc "Release string, e.g. `22.11` or `unstable`";
          };

          config = lib.mkOption {
            type = lib.types.unspecified;
            description = lib.mdDoc "Config to be added to image";
            default = {};
          };

          imageName = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = lib.mdDoc "Override release/type based image namingnamintype";
            default = "${config.release}/${config.type}";
          };

          imageAlias = lib.mkOption {
            type = lib.types.str;
            description = lib.mdDoc "Alias for image when importing into LXD";
            default = "nixos/${config.imageName}";
          };

          # private

          app = lib.mkOption {
            type = lib.types.unspecified;
            description = lib.mdDoc "Apps to be added to the flake";
            readOnly = true;
          };

          check = lib.mkOption {
            type = lib.types.unspecified;
            description = lib.mdDoc "Checks to be added to the flake";
            readOnly = true;
          };

          imageFile = lib.mkOption {
            type = lib.types.unspecified;
            description = lib.mdDoc "Path to the file to be imported, e.g. squashfs or qcow2";
            readOnly = true;
          };

          importScript = lib.mkOption {
            type = lib.types.package;
            description = lib.mdDoc "Script to import an image";
            readOnly = true;
          };

          nixosConfiguration = lib.mkOption {
            type = lib.types.unspecified;
            description = lib.mdDoc "nixosConfiguration to be added to the flake";
            readOnly = true;
          };
        };

        config = let
          normalizedRelease = builtins.replaceStrings ["."] [""] config.release;
          safeName = "nixos/" + (builtins.replaceStrings ["."] [""] config.imageName);
          appSafeName = "import/${safeName}";
        in {
          imageFile =
            if (config.type == "virtual-machine")
            then config.nixosConfiguration.config.system.build.qemuImage + "/nixos.qcow2"
            else config.nixosConfiguration.config.system.build.squashfs;

          importScript = withSystem config.system ({pkgs, ...}:
            pkgs.writeScript "import-${config.type}-${normalizedRelease}" ''
              [ -n "$1" ] && REMOTE="$1:"

               echo ":: Running importer ${config.imageAlias}"
               lxc image import --alias ${config.imageAlias} \
                 ${config.nixosConfiguration.config.system.build.metadata}/tarball/nixos-lxd-metadata-${config.system}.tar.xz \
                 ${config.imageFile} \
                 $REMOTE
            '');

          nixosConfiguration = config.nixpkgs.lib.nixosSystem {
            inherit (config) system;

            modules = [
              ../modules/${config.type}.nix

              config.config
              {
                system.stateVersion = config.release;

                _module.args.lxd = config.metadata;
              }
            ];
          };

          app.${config.system}.${appSafeName} = {
            type = "app";
            program = builtins.toString config.importScript;
          };

          check.${config.system}.${safeName} = withSystem config.system (
            {pkgs, ...}:
              import ../lib/nixos-test.nix {
                inherit pkgs;
                inherit (config) type;

                makeTest = import (pkgs.path + "/nixos/tests/make-test-python.nix");
                testName = "image-${name}";

                importerBin = config.importScript;
                image = config.imageAlias;

                lxd = self.packages.${config.system}.lxd;
              }
          );
        };
      }));
    };
  };

  config = {
    flake.nixosConfigurations = nixosConfigurations;

    perSystem = {system, ...}: {
      apps = lib.mkIf (builtins.hasAttr system apps) (lib.mkMerge apps.${system});
      checks = lib.mkIf (builtins.hasAttr system checks) (lib.mkMerge checks.${system});
    };
  };
}
