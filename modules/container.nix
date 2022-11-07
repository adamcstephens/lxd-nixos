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

    # TODO: build rootfs as squashfs for faster unpack
    system.build.tarball = pkgs.callPackage (modulesPath + "/../lib/make-system-tarball.nix") {
      fileName = "nixos-lxd-image-${pkgs.stdenv.hostPlatform.system}";
      extraArgs = "--owner=0";

      storeContents = [
        {
          object = config.system.build.toplevel;
          symlink = "none";
        }
      ];

      contents = [
        {
          source = config.system.build.toplevel + "/init";
          target = "/sbin/init";
        }
      ];

      extraCommands = "mkdir -p proc sys dev";
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
