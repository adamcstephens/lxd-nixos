{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.virtualisation.lxd;

  preseedYAML = pkgs.writeText "lxd-preseed" (lib.generators.toYAML {} cfg.preseed);

  # device = lib.types.submodule ({
  #   name,
  #   config,
  #   ...
  # }: {
  #   options = {
  #     name = lib.mkOption {
  #       default = name;
  #       type = lib.types.str;
  #       description = lib.mdDoc ''
  #         Name of the device
  #       '';
  #     };

  #     deviceConfig = lib.mkOption {
  #       default = config;
  #       type = lib.types.attrsOf lib.types.str;
  #     };
  #   };
  # });

  # device = lib.mkOption {
  #   type = lib.types.attrsOf lib.types.str;
  # };

  config = lib.mkOption {
    default = null;
    type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
  };

  devices = lib.mkOption {
    default = null;
    type = lib.types.nullOr (lib.types.attrsOf (lib.types.attrsOf lib.types.str));
  };

  profile = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          Name of the profile
        '';
      };

      description = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          Description of the profile
        '';
      };

      project = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          Project to associate profile to
        '';
      };

      inherit config devices;
    };
  };

  profiles = lib.mkOption {
    type = lib.types.listOf profile;
    description = lib.mdDoc ''
      List of profiles
    '';
    default = [];
  };

  network = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          Name of the network
        '';
      };

      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = lib.mdDoc ''
          Description of the network
        '';
        default = null;
      };

      project = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = lib.mdDoc ''
          Project to associate network to
        '';
        default = null;
      };

      target = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = lib.mdDoc ''
          Cluster member name for target
        '';
        default = null;
      };

      type = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          The network type (refer to doc/networks.md)
        '';
      };

      inherit config;
    };
  };

  networks = lib.mkOption {
    type = lib.types.listOf network;
    description = lib.mdDoc ''
      List of networks
    '';
    default = [];
  };
in {
  options.virtualisation.lxd = {
    preseed = lib.mkOption {
      default = null;
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          inherit networks profiles;
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
