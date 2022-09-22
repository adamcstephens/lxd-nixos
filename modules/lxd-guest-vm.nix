{...}: {
  imports = [
    ./lxd-agent.nix
    ./lxd-image-vm.nix
  ];

  documentation.enable = true;
  documentation.nixos.enable = true;
  environment.noXlibs = false;
}
