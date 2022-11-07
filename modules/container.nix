{
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}: let
  # Add the overrides from lxd distrobuilder
  # https://github.com/lxc/distrobuilder/blob/f15eec09df7b04f1bede66b0f31354da66748c9a/distrobuilder/main.go#L622
  systemdOverride = pkgs.writeText "lxd-systemd-override" ''
    [Service]
    ProcSubset=all
    ProtectProc=default
    ProtectControlGroups=no
    ProtectKernelTunables=no
    NoNewPrivileges=no
  '';
in {
  imports = [
    ./agent.nix
    ./common.nix
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];

  config = {
    boot.isContainer = true;

    system.build.squashfs = pkgs.callPackage ../lib/make-squashfs.nix {
      fileName = "nixos-lxd-image-${pkgs.stdenv.hostPlatform.system}";

      storeContents = [config.system.build.toplevel];

      pseudoFiles = [
        "/sbin d 0755 0 0"
        "/sbin/init s 0555 0 0 ${config.system.build.toplevel}/init"
        "/dev d 0755 0 0"
        "/proc d 0555 0 0"
        "/sys d 0555 0 0"
      ];
    };

    systemd.packages = [
      (pkgs.runCommandNoCC "toplevel-overrides.conf" {
          preferLocalBuild = true;
          allowSubstitutes = false;
        } ''
          mkdir -p $out/etc/systemd/system/service.d/
          cp ${systemdOverride} $out/etc/systemd/system/service.d/lxc.conf
        '')
    ];

    system.activationScripts.installInitScript = lib.mkForce ''
      ln -fs $systemConfig/init /sbin/init
    '';

    # We also have to do this currently for LXC.
    # Don't know why.
    # https://github.com/NixOS/nixpkgs/issues/157918
    systemd.suppressedSystemUnits = [
      "sys-kernel-debug.mount"
    ];

    boot.postBootCommands = ''
      # After booting, register the contents of the Nix store in the Nix
      # database.
      if [ -f /nix-path-registration ]; then
        ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration &&
        rm /nix-path-registration
      fi

      # nixos-rebuild also requires a "system" profile
      ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
    '';

    # explicitly set /run to shared so bind mounts work, e.g. LoadCredential=
    boot.specialFileSystems = {
      "/run".options = ["shared"];
    };
  };
}
