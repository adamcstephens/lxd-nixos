{
  description = "Let's focus on LXD and Nix together.";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs-2205";
    nixpkgs-2205.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit self;} {
      systems = ["x86_64-linux"];

      imports = [
        ./images.nix
      ];

      perSystem = {
        pkgs,
        system,
        self',
        ...
      }: {
        _module.args.pkgs = inputs.nixpkgs-2205.legacyPackages.${system};

        devShells.default = pkgs.mkShellNoCC {
          buildInputs = [
            pkgs.cachix
            pkgs.just
            pkgs.lxd
          ];
        };
      };
    }
    // {
      nixosModules.agent = import ./modules/agent.nix;
      nixosModules.container = import ./modules/container.nix;
      nixosModules.imageMetadata = import ./modules/image-metadata.nix;
      nixosModules.vm = import ./modules/vm.nix;
    };
}
