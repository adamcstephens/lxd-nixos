# lxd-nixos

NixOS support for LXD. Flake (parts) native.

Features:

- Container and VM image building
- Importing and customizing images

## Flake setup

Add to your flake

```
inputs.lxd-nixos.url = "git+https://codeberg.org/adamcstephens/lxd-nixos";
```

## Import Images

There are multiple supported ways to import and customize images.

### Base Images

This flake provides a set of base NixOS images that can be imported without any configuration.

Use these commands to build images for both containers and VMs and then import them into LXD

```
$ nix run git+https://codeberg.org/adamcstephens/lxd-nixos#import/nixos/2305/container
$ nix run git+https://codeberg.org/adamcstephens/lxd-nixos#import/nixos/unstable/container

# now available for running
$ lxc launch nixos/23.05/container test1
```

### Customized Base Images

These customized base images use the same names as the default base images, but allow for overriding the configuration. By using `lxd.imageDefaults.extraConfig`, nixos configuration can be applied to all the base images.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lxd-nixos.url = "git+https://codeberg.org/adamcstephens/lxd-nixos";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.lxd-nixos.flakeModules.images
        inputs.lxd-nixos.flakeModules.baseImages
      ];

      systems = ["x86_64-linux" "aarch64-linux"];

      lxd.imageDefaults.extraConfig = {
        _module.args = {
          inherit inputs;
          hostname = "bootstrap";
        };

        imports = [
          ../core
          inputs.home-manager.nixosModules.home-manager
          inputs.ragenix.nixosModules.age
        ];
      };
    };
}
```

### Standalone Images

Images can be built, checked and imported by creating custom `lxd.images`.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lxd-nixos.url = "git+https://codeberg.org/adamcstephens/lxd-nixos";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.lxd-nixos.flakeModules.images
      ];

      systems = ["x86_64-linux" "aarch64-linux"];

      lxd.images = {
        mycontainer = {
          release = "unstable";
          nixpkgs = inputs.nixpkgs;
          system = "x86_64-linux";
          imageName = "mycontainer";
          type = "container";
          config = {
            environment.systemPackages = [
              inputs.nixpkgs.legacyPackages.x86_64-linux.hello
            ];
          };
        };
      };
    };
}
```

### Generate Images from nixosConfigurations

Use `lxd.generateImporters` to automatically create import apps for all nixosConfigurations.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lxd-nixos.url = "git+https://codeberg.org/adamcstephens/lxd-nixos";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.lxd-nixos.flakeModules.images
      ];

      systems = ["x86_64-linux" "aarch64-linux"];

      lxd.generateImporters = true;

      nixosConfigurations = {
        test = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            inputs.lxd-nixos.nixosModules.virtual-machine
          ];
        };
      };
    };
}
```

## Background

Much of this code was copied from nixpkgs with a goal of quicker iteration and dedicated focus on LXD. I claim no
credit and thank all the previous contributors.
