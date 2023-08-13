{...}: {
  perSystem = {
    inputs',
    pkgs,
    system,
    self',
    ...
  }: {
    packages = rec {
      inherit (pkgs.callPackage ../packages/lxd {}) lxd-unwrapped;

      lxd = pkgs.callPackage ../packages/lxd/wrapper.nix {
        OVMFFull = ovmf;
        lxd-unwrapped = pkgs.lxd-unwrapped;
      };

      ovmf = pkgs.callPackage ../packages/ovmf {};
    };
  };
}
