default:
    just -l

import release='unstable':
    nix run .#import-image-container-{{release}}
    # nix run .#import-image-vm-{{release}}

clean:
    lxc image list -c LF -f compact | grep -v nixos | awk '{print $1}' | egrep '^[0-9a-f]' | xargs lxc image delete

push:
    nix build .#image-container-2205 --json | jq -r '.[].outputs | to_entries[].value' | cachix push lxd-nix
    nix build .#image-container-unstable --json | jq -r '.[].outputs | to_entries[].value' | cachix push lxd-nix

store-bootstrap:
    sudo nix build github:adamcstephens/lxd-nix#import-image-container-2205 --store /srv
    sudo nix build github:adamcstephens/lxd-nix#import-image-container-unstable --store /srv
