{
  lib,
  inputs,
  ...
}: {
  flake.imageImporters = flake: let
    machines = flake.nixosConfigurations;
    lxdMachines = lib.filterAttrs (_: value: (isVM value) || (isContainer value)) machines;

    vmPath = ["config" "system" "build" "qemuImage"];
    containerPath = ["config" "system" "build" "tarball"];

    isVM = host: lib.hasAttrByPath vmPath host;
    isContainer = host: lib.hasAttrByPath containerPath host;
  in
    lib.mapAttrs' (
      name: value: let
        appName = "lxd-import-${name}";
        imageName = "nixos/${name}";
        imageSystem = value.config.nixpkgs.localSystem.system;

        lxdMeta = value.config.system.build.metadata;
        imageAttr =
          if (isVM value)
          then value.config.system.build.qemuImage
          else value.config.system.build.tarball;
        imagePathFile =
          if (isVM value)
          then imageAttr + "/nixos.qcow2"
          else imageAttr + "/tarball/nixos-lxd-image-${imageSystem}.tar.xz";

        # lib.hasAttrByPath vmPath name;
        script = inputs.nixpkgs.legacyPackages.x86_64-linux.writeScriptBin "import" ''
          echo "Importing container image ${appName}"
          lxc image import --alias ${imageName} \
            ${lxdMeta}/tarball/nixos-lxd-metadata-${imageSystem}.tar.xz \
            ${imagePathFile}
        '';
      in
        # lib.nameValuePair appName {
        #   type = "app";
        #   program = script.outPath;
        # }
        lib.nameValuePair appName script
    )
    lxdMachines;
}
