default:
    just -l

import:
    nix run .#import-image-container
    nix run .#import-image-vm

clean:
    lxc image list -c LF | grep nixos | awk '{print $4}' | egrep '^[0-9a-f]' | xargs lxc image delete
