{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.virtualisation.lxd.instances;
  instances = pkgs.writeText "lxd-instances" (builtins.toJSON cfg);
in {
  options.virtualisation.lxd.instances = lib.mkOption {
    default = {};
    type = lib.types.attrsOf (lib.types.submodule ({
      name,
      config,
      options,
    }: {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = lib.mkDoc "Instance name";
        };
        type = lib.mkOption {
          type = lib.types.strMatching "(container|virtual-machine)";
          default = "container";
          description = lib.mkDoc "Instance type (container|virtual-machine)";
        };
        project = lib.mkOption {
          type = lib.types.str;
          default = null;
          description = lib.mkDoc "Project to manage instance in";
        };
        config = lib.mkOption {
          type = lib.types.attrs;
          default = {};
          description = lib.mkDoc "Instance configuration";
        };
        devices = lib.mkOption {
          type = lib.types.attrs;
          default = {};
          description = lib.mkDoc "Instance devices";
        };
        profiles = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = lib.mkDoc "Instance profiles";
        };
      };
    }));
  };
  config = lib.mkIf (cfg != {}) {
    system.activationScripts.lxd-instances.text = ''
      echo ${instances}
    '';
  };
}
