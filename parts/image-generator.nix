{
  config,
  lib,
  self,
  ...
}: let
  vmPath = ["config" "system" "build" "qemuImage"];
  containerPath = ["config" "system" "build" "squashfs"];

  isVM = host: lib.hasAttrByPath vmPath host;
  isContainer = host: lib.hasAttrByPath containerPath host;

  machines = config.flake.nixosConfigurations;
  lxdMachines = lib.filterAttrs (_: value: (isVM value) || (isContainer value)) machines;
in {
  options = {
    lxd.generateImporters = lib.mkEnableOption (lib.mdDoc "Enable image import apps for all flake nixosConfigurations.");
  };

  config = lib.mkIf (config.lxd.generateImporters) {
    perSystem = {system, ...}: {
      apps =
        lib.mapAttrs' (name: nixosConfig: (lib.nameValuePair "import/${name}" {
          type = "app";
          program = builtins.toString (self.lib.importScript {
            type =
              if (isVM nixosConfig)
              then "virtual-machine"
              else "container";
            release = nixosConfig.config.system.nixos.release;
            system = nixosConfig.pkgs.system;
            imageAlias = "nixos/${name}";
            nixosConfiguration = nixosConfig;
          });
        }))
        lxdMachines;
    };
  };
}
