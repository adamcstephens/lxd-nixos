{ config
, lib
, pkgs
, ...
}:
with lib; {
  system.build.metadata = pkgs.callPackage ../../lib/make-system-tarball.nix {
    contents =
      [
        {
          source = toYAML "metadata.yaml" {
            architecture = builtins.elemAt (builtins.match "^([a-z0-9_]+).+" (toString pkgs.system)) 0;
            creation_date = 1;
            properties = {
              description = "NixOS ${config.system.nixos.codeName} ${config.system.nixos.label} ${pkgs.system}";
              os = "nixos";
              release = "${config.system.nixos.codeName}";
            };
            templates = templates.properties;
          };
          target = "/metadata.yaml";
        }
      ]
      ++ templates.files;
  };
}
