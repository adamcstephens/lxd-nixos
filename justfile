default:
    just -l

clean:
    lxc image list -c LF -f compact | grep -v nixos | awk '{print $1}' | egrep '^[0-9a-f]' | xargs lxc image delete

nixpkgs-bump:
    nix flake lock $(rg -INo "nixpkgs.*url" | cut -f 1 -d \. | while read line; do echo -n "--update-input $line "; done)

push:
    nix build .#image-container-2205 --json | jq -r '.[].outputs | to_entries[].value' | cachix push lxd-nix
    nix build .#image-container-unstable --json | jq -r '.[].outputs | to_entries[].value' | cachix push lxd-nix

