{withSystem, ...}: {
  flake.lib = {
    importScript = image: let
      normalizedRelease = builtins.replaceStrings ["."] [""] image.release;

      imageFile =
        if (image.type == "virtual-machine")
        then image.nixosConfiguration.config.system.build.qemuImage + "/nixos.qcow2"
        else image.nixosConfiguration.config.system.build.squashfs;
    in
      withSystem image.system ({pkgs, ...}:
        pkgs.writeScript "import-${image.type}-${normalizedRelease}" ''
          [ -n "$1" ] && REMOTE="$1:"

           echo ":: Running importer ${image.imageAlias}"
           lxc image import --alias ${image.imageAlias} \
             ${image.nixosConfiguration.config.system.build.metadata}/tarball/nixos-lxd-metadata-${image.system}.tar.xz \
             ${imageFile} \
             $REMOTE
        '');
  };
}
