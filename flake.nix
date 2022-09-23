{
  description = "Let's focus on LXD and Nix together.";

  outputs = {
    self,
    nixpkgs,
  }: {
    nixosModules.lxd-agent = import ./modules/lxd-agent.nix;
    nixosModules.lxd-container = import ./modules/lxd-container.nix;
    nixosModules.lxd-image-metadata = import ./modules/lxd-image-image-metadata.nix;
    nixosModules.lxd-vm = import ./modules/lxd-vm.nix;
  };
}
