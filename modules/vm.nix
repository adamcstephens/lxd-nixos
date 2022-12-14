{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  options = {
    lxd-image-vm = {
      vmDerivationName = lib.mkOption {
        type = lib.types.str;
        default = "nixos-lxd-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
        description = ''
          The name of the derivation for the LXD VM image.
        '';
      };
    };
  };

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./agent.nix
    ./common.nix
  ];

  config = {
    system.build.qemuImage = import (modulesPath + "/../lib/make-disk-image.nix") {
      name = config.lxd-image-vm.vmDerivationName;

      inherit pkgs lib config;

      partitionTableType = "efi";
      format = "qcow2-compressed";
      copyChannel = true;
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
  };
}
