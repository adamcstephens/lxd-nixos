{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
with lib; let
  cfg = config.lxd-image-vm;
in {
  options = {
    lxd-image-vm = {
      vmDerivationName = mkOption {
        type = types.str;
        default = "nixos-lxd-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
        description = ''
          The name of the derivation for the LXD VM image.
        '';
      };
    };
  };

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./lxd-agent.nix
  ];

  config = {
    system.build.qemuImage = import (modulesPath + "/../lib/make-disk-image.nix") {
      name = cfg.vmDerivationName;

      inherit pkgs lib config;

      partitionTableType = "efi";
      format = "qcow2";
      copyChannel = false;
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        autoResize = true;
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-label/ESP";
        fsType = "vfat";
      };
    };

    boot.growPartition = true;
    boot.loader.systemd-boot.enable = true;
    boot.kernelParams = ["console=tty1" "console=ttyS0"];
    systemd.services."serial-getty@ttyS0" = {
      enable = true;
      wantedBy = ["getty.target"];
      serviceConfig.Restart = "always";
    };

    # swapDevices = [
    #   {
    #     device = "/var/swap";
    #     size = 2048;
    #   }
    # ];

    networking.useDHCP = mkDefault true;

    documentation.nixos.enable = mkDefault false;
    documentation.enable = mkDefault false;
    programs.command-not-found.enable = mkDefault false;

    services.openssh.enable = mkDefault true;
  };
}
