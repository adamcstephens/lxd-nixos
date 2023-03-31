# lxd-nixos

NixOS support for LXD. Flake (parts) native.

Features:

- NixOS modules for Containers and VMs
- Packages for LTS and Latest releases
- Container and VM image building
- Importing and customizing images

## Importing Images

Use these commands to build images for both containers and VMs and then import them into LXD

```
$ nix run git+https://codeberg.org/adamcstephens/lxd-nixos#import/nixos/2211/container
$ nix run git+https://codeberg.org/adamcstephens/lxd-nixos#import/nixos/unstable/container

# now available for running
$ lxc launch nixos/22.11/container test1
```

## Flake setup

Add to your flake

```
inputs.lxd-nixos.url = "git+https://codeberg.org/adamcstephens/lxd-nixos";
```

## Packages

Nixpkgs provides an LXD package, but it is missing multiple features. While efforts continue to improve that package, this flake will strive to provide a fully functional installation.

The following packages are provided

* `lxd` - Latest release of LXD
* `lxd.client` - Latest client
* `lxd-lts` - LTS release of LXD, currently 5.0.x
* `lxd-lts.client` - LTS client only

## NixOS Modules

Use one of the following to configure a nixosConfiguration as an LXD guest.

### Container Guest

```
  imports = [
    inputs.lxd-nixos.nixosModules.container
  ];
```

### VM Guest

```
  imports = [
    inputs.lxd-nixos.nixosModules.virtual-machine
  ];
```

## Import your own images

This requires flake-parts.

1. Add the nixosModule for the container or vm to a nixosConfiguration

2. Update your flake to include the importers in your packages and define an image. Here's a full example, but you may want to look at the options in [the flake module](./parts/images.nix) and the [images built by this repo](./images.nix).

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

3. Run `nix flake show` to see newly added packages for `import/nixos/container` and run the importer

``` sh
$ nix run .#import/nixos/container
```

4. Use your new image!

``` sh
$ lxc launch nixos/mycontainer u1
Creating u1
Starting u1

$ lxc exec u1 bash

[root@nixos:~]#
```

## Background

Much of this code was copied from nixpkgs with a goal of quicker iteration and dedicated focus on LXD. I claim no
credit and thank all the previous contributors.
