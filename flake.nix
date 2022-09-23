{
  description = "Let's focus on LXD and Nix together.";

  outputs = {
    self,
    nixpkgs,
  }: {
    nixosModules.agent = import ./modules/agent.nix;
    nixosModules.container = import ./modules/container.nix;
    nixosModules.image-metadata = import ./modules/image-image-metadata.nix;
    nixosModules.vm = import ./modules/vm.nix;
  };
}
