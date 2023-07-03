{
  acl,
  apparmor-parser,
  apparmor-profiles,
  attr,
  bash,
  btrfs-progs,
  cdrkit,
  criu,
  dnsmasq,
  e2fsprogs,
  getent,
  gnutar,
  gptfdisk,
  gzip,
  iproute2,
  iptables,
  kmod,
  lxd-unwrapped,
  lib,
  linkFarm,
  makeWrapper,
  minio,
  nftables,
  OVMFFull,
  qemu_kvm,
  qemu-utils,
  rsync,
  squashfsTools,
  symlinkJoin,
  util-linux,
  writeShellScriptBin,
  xz,
  zfs,
  nixosTests,
}: let
  lxd = lxd-unwrapped;
  binPath = [
    acl
    attr
    bash
    btrfs-progs
    cdrkit
    criu
    dnsmasq
    e2fsprogs
    getent
    gnutar
    gptfdisk
    gzip
    iproute2
    iptables
    kmod
    minio
    nftables
    qemu_kvm
    qemu-utils
    rsync
    squashfsTools
    util-linux
    xz
    zfs

    (writeShellScriptBin "apparmor_parser" ''
      exec '${apparmor-parser}/bin/apparmor_parser' -I '${apparmor-profiles}/etc/apparmor.d' "$@"
    '')
  ];
in
  symlinkJoin {
    name = "lxd-${lxd.version}";

    paths = [lxd lxd.client];

    nativeBuildInputs = [makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/lxd --prefix PATH : ${lib.makeBinPath binPath}:${qemu_kvm}/libexec:${zfs}/lib/udev:$out/bin --set LXD_OVMF_PATH ${OVMFFull.fd}/FV
    '';

    passthru.tests = {
      inherit (nixosTests) lxd lxd-nftables lxd-qemu;
    };

    inherit (lxd) meta client;
  }
