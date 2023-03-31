{...}: {
  perSystem = {
    inputs',
    pkgs,
    system,
    self',
    ...
  }: let
    lxdOverrides = {
      OVMFFull = self'.packages.ovmf;
      btrfs-progs = pkgs.btrfs-progs.overrideAttrs (old: rec {
        version = "6.0";
        src = pkgs.fetchurl {
          url = "mirror://kernel/linux/kernel/people/kdave/btrfs-progs/btrfs-progs-v${version}.tar.xz";
          sha256 = "sha256-Rp4bLshCpuZISK5j3jAiRG+ACel19765GRkfE3y91TQ=";
        };
      });
    };
  in {
    packages = {
      inherit
        (pkgs.callPackage ../packages/lxd {
          inherit (inputs'.nixpkgs-unstable.legacyPackages) dqlite raft-canonical;
        })
        lxd-unwrapped-lts
        lxd-unwrapped
        ;

      ovmf = pkgs.callPackage ../packages/ovmf {};

      lxd = pkgs.callPackage ../packages/lxd/wrapper.nix {
        inherit (lxdOverrides) OVMFFull;
        lxd-unwrapped = self'.packages.lxd-unwrapped;
      };

      lxd-lts = pkgs.callPackage ../packages/lxd/wrapper.nix {
        inherit (lxdOverrides) OVMFFull btrfs-progs;
        lxd-unwrapped = self'.packages.lxd-unwrapped-lts;
      };
    };
  };
}
