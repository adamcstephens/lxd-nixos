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
    nixosModules.x86_64-linux.lxd-image = import ./images/lxd-image.nix {inherit nixpkgs;};

    packages.x86_64-linux.hello =
      (import lib/eval-config.nix {
        inherit system;
        modules = [
          self.nixosModules.x86_64-linux.lxd-image
        ];
      })
      .config
      .system
      .build
      .tarball;

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
  };
}
