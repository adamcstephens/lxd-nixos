default:
    just -l

import release='unstable':
    nix run .#import-image-container-{{release}}
    # nix run .#import-image-vm-{{release}}

clean:
    lxc image list -c LF | grep nixos | awk '{print $4}' | egrep '^[0-9a-f]' | xargs lxc image delete
