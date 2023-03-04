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
  gawk,
  gnutar,
  gptfdisk,
  gzip,
  iproute2,
  iptables,
  kmod,
  lxc,
  lxd-unwrapped,
  lib,
  libnvidia-container,
  linkFarm,
  makeWrapper,
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
  nixosTests,
  useQemu ? true,
}: let
  lxd = lxd-unwrapped;
  binPath =
    [
      acl
      attr
      bash
      btrfs-progs
      cdrkit
      criu
      dnsmasq
      gnutar
      gptfdisk
      gzip
      iproute2
      iptables
      libnvidia-container
      kmod
      nftables
      rsync
      squashfsTools
      util-linux
      xz

      (writeShellScriptBin "apparmor_parser" ''
        exec '${apparmor-parser}/bin/apparmor_parser' -I '${apparmor-profiles}/etc/apparmor.d' "$@"
      '')
    ]
    ++ (lib.optionals useQemu [qemu-utils qemu_kvm]);

  firmware = linkFarm "lxd-firmware" [
    {
      name = "share/OVMF/OVMF_CODE.fd";
      path = "${OVMFFull.fd}/FV/OVMF_CODE.fd";
    }
    {
      name = "share/OVMF/OVMF_VARS.fd";
      path = "${OVMFFull.fd}/FV/OVMF_VARS.fd";
    }
    {
      name = "share/OVMF/OVMF_VARS.ms.fd";
      path = "${OVMFFull.fd}/FV/OVMF_VARS.fd";
    }
  ];

  LXD_OVMF_PATH = "${firmware}/share/OVMF";
in
  symlinkJoin {
    name = "lxd-${lxd.version}";

    paths = [lxd lxd.client];

    nativeBuildInputs = [makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/lxd --prefix PATH : ${lib.makeBinPath binPath}:$out/bin --set LXD_LXC_HOOK $out/share/lxc/hooks ${
        lib.optionalString useQemu " --set LXD_OVMF_PATH ${LXD_OVMF_PATH}"
      }

      # support nvidia.runtime=true. just a shell script so avoid including all of lxc
      mkdir -p $out/share/lxc/hooks
      cp ${lxc}/share/lxc/hooks/nvidia $out/share/lxc/hooks/
      wrapProgram $out/share/lxc/hooks/nvidia --prefix PATH : ${lib.makeBinPath [gawk libnvidia-container]}
    '';

    passthru.tests = {
      inherit (nixosTests) lxd lxd-nftables lxd-qemu;
    };

    inherit (lxd) meta client;
  }
