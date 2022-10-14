# lxd-nix

NixOS support for LXD. Flake native.

Features:

- NixOS modules
- Container and VM image building
- Importing (just uses `lxc`)

## import images directly

Use these commands to build images for both containers and VMs and then import them into LXD

_Note_ Only one will hold the image alias. Still troubleshooting this.

```
nix run github:adamcstephens/lxd-nix#import-image-container-unstable
# now available for running
lxc launch nixos/unstable test1
```

## NixOS Modules

Add to your flake

```
inputs.lxd-nix.url = "github:adamcstephens/lxd-nix"
inputs.lxd-nix.inputs.nixpkgs.follows = "nixpkgs"
```

Use one of the following to configure a nixosConfiguration as an LXD guest.

### Container Guest

```
  imports = [
    inputs.lxd-nix.nixosModules.container
  ];
```

### VM Guest

```
  imports = [
    inputs.lxd-nix.nixosModules.vm
  ];
```

## Background

Much of this code was copied from nixpkgs with a goal of quicker iteration and dedicated focus on LXD. I claim no
credit and thank all the previous contributors.
