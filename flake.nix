{
  description = "A very basic flake";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    nixosModules.lxd-image = import ./modules/lxd-image.nix;
    nixosModules.lxd-image-vm = import ./modules/lxd-image-vm.nix;
    nixosModules.lxd-guest-vm = import ./modules/lxd-guest-vm.nix;

    # packages.x86_64-linux.lxd-image = nixpkgs.legacyPackages.x86_64-linux.callPackage ./images/lxd-image.nix {lxd-image = self;};
    packages.x86_64-linux.lxd-image = nixpkgs.lib.nixosSystem {
      inherit pkgs;
      system =
        if system != null
        then system
        else pkgs.system;
      modules = [
        self.nixosModules.lxd-image
      ];
    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
  };
}
