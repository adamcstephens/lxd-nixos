# lxd-nixos

NixOS support for LXD. Flake native.

Features:

- NixOS modules
- Container and VM image building
- Importing (just uses `lxc`)

## import images directly

Use these commands to build images for both containers and VMs and then import them into LXD

```
nix run git+https://codeberg.org/adamcstephens/lxd-nixos#lxd-import-image-container-2211
nix run git+https://codeberg.org/adamcstephens/lxd-nixos#lxd-import-image-container-unstable

# now available for running
lxc launch nixos/22.11/container test1
```

## NixOS Modules

Add to your flake

```
inputs.lxd-nixos.url = "git+https://codeberg.org/adamcstephens/lxd-nixos"
```

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
    inputs.lxd-nixos.nixosModules.vm
  ];
```

## Import your own images

1. Add the nixosModule for the container or vm to a nixosConfiguration

2. Update your flake to include the importers in your packages

```nix
packages = inputs.lxd-nixos.imageImporters self;
```

3. Run `nix flake show` to see newly added packages for `lxd-import-<hostname>` and run the importer

``` sh
nix run .#lxd-import-mynixos
```

## Background

Much of this code was copied from nixpkgs with a goal of quicker iteration and dedicated focus on LXD. I claim no
credit and thank all the previous contributors.
