{
  config,
  lib,
  pkgs,
  ...
}: let
  # this is a port of the distrobuilder lxd-agent generator
  # https://github.com/lxc/distrobuilder/blob/master/generators/lxd-agent.go
  preStartScript = ''
    PREFIX="/run/lxd_agent"

    # Functions.
    mount_virtiofs() {
        mount -t virtiofs config "''${PREFIX}/.mnt" >/dev/null 2>&1
    }

    mount_9p() {
        modprobe 9pnet_virtio >/dev/null 2>&1 || true
        mount -t 9p config "''${PREFIX}/.mnt" -o access=0,trans=virtio,size=1048576 >/dev/null 2>&1
    }

    fail() {
        umount -l "''${PREFIX}" >/dev/null 2>&1 || true
        rmdir "''${PREFIX}" >/dev/null 2>&1 || true
        echo "''${1}"
        exit 1
    }

    # Setup the mount target.
    umount -l "''${PREFIX}" >/dev/null 2>&1 || true
    mkdir -p "''${PREFIX}"
    mount -t tmpfs tmpfs "''${PREFIX}" -o mode=0700,size=50M
    mkdir -p "''${PREFIX}/.mnt"

    # Try virtiofs first.
    mount_virtiofs || mount_9p || fail "Couldn't mount virtiofs or 9p, failing."

    # Copy the data.
    cp -Ra "''${PREFIX}/.mnt/"* "''${PREFIX}"

    # Unmount the temporary mount.
    umount "''${PREFIX}/.mnt"
    rmdir "''${PREFIX}/.mnt"

    # Fix up permissions.
    chown -R root:root "''${PREFIX}"
  '';
in {
  systemd.services.lxd-agent = {
    unitConfig = {
      Description = "LXD - agent";
      Documentation = "https://linuxcontainers.org/lxd";
      ConditionPathExists = "/dev/virtio-ports/org.linuxcontainers.lxd";
      # Before = "cloud-init.target cloud-init.service cloud-init-local.service";
      DefaultDependencies = "no";
      StartLimitInterval = "60";
      StartLimitBurst = "10";
    };

    serviceConfig = {
      Type = "notify";
      WorkingDirectory = "-/run/lxd_agent";
      ExecStart = "/run/lxd_agent/lxd-agent";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    preStart = preStartScript;

    enable = true;
    wantedBy = ["multi-user.target"];
    path = [pkgs.kmod pkgs.util-linux];
  };

  systemd.paths.lxd-agent = {
    enable = true;
    wantedBy = ["multi-user.target"];
    pathConfig.PathExists = "/dev/virtio-ports/org.linuxcontainers.lxd";
  };
}
