{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.virtualisation.lxd;

  preseedYAML = pkgs.writeText "lxd-preseed" (lib.generators.toYAML {} cfg.preseed);

  device = lib.types.submodule ({
    name,
    config,
    ...
  }: {
    options = {
      name = lib.mkOption {
        default = name;
        type = lib.types.str;
        description = lib.mdDoc ''
          Name of the device
        '';
      };

      deviceConfig = lib.mkOption {
        default = config;
        type = lib.types.attrsOf lib.types.str;
      };
    };
  });

  profile = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          Name of the profile
        '';
      };
      devices = lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.attrsOf device);
      };
    };
  };
in {
  options.virtualisation.lxd = {
    preseed = lib.mkOption {
      default = null;
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          profiles = lib.mkOption {
            default = [];
            type = lib.types.listOf profile;
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.lxd-preseed = lib.mkIf (! (builtins.isNull cfg.preseed)) {
      description = "LXD initialization with preseed file";
      wantedBy = ["multi-user.target"];
      requires = ["lxd.service"];
      after = ["lxd.service"];

      script = ''
        ${pkgs.coreutils}/bin/cat ${preseedYAML} | ${cfg.package}/bin/lxd init --preseed
      '';

      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}
