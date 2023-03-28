{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.virtualisation.lxd;

  preseedYAML = pkgs.writeText "lxd-preseed" (lib.generators.toYAML {} cfg.preseed);

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
        type = lib.types.nullOr lib.types.str;
        description = lib.mdDoc ''
          Description of the profile
        '';
        default = null;
      };

      config = lib.mkOption {
        default = null;
        description = lib.mdDoc ''
          Instance configuration map (refer to doc/instances.md)
        '';
        type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
      };

      inherit devices;
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

      type = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          The network type (refer to doc/networks.md)
        '';
      };

      config = lib.mkOption {
        default = null;
        description = lib.mdDoc ''
          Network configuration map (refer to doc/networks.md)
        '';
        type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
      };
    };
  };

  networks = lib.mkOption {
    type = lib.types.listOf network;
    description = lib.mdDoc ''
      List of networks
    '';
    default = [];
  };

  storage_pool = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          Name of the storage pool
        '';
      };

      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = lib.mdDoc ''
          Description of the pool
        '';
        default = null;
      };

      driver = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          Storage pool driver (btrfs, ceph, cephfs, dir, lvm or zfs)
        '';
      };

      config = lib.mkOption {
        default = null;
        description = lib.mdDoc ''
          Storage pool configuration map (refer to doc/storage.md)
        '';
        type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
      };
    };
  };

  storage_pools = lib.mkOption {
    type = lib.types.listOf storage_pool;
    description = lib.mdDoc ''
      List of storage pools
    '';
    default = [];
  };
in {
  options.virtualisation.lxd = {
    preseed = lib.mkOption {
      default = null;
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          config = lib.mkOption {
            default = null;
            description = lib.mdDoc ''
              Daemon configuration
            '';
            type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
          };

          inherit networks profiles storage_pools;
        };
      });
      description = lib.mdDoc ''
        Preseed configuration. See https://linuxcontainers.org/lxd/docs/latest/howto/initialize/#non-interactive-configuration

        Changes to this will be re-applied to LXD which will overwrite existing entities or create missing ones
      '';
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
