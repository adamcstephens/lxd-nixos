{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
with lib; let
  templateSubmodule = {...}: {
    options = {
      enable = mkEnableOption "this template";

      target = mkOption {
        description = "Path in the container";
        type = types.path;
      };
      template = mkOption {
        description = ".tpl file for rendering the target";
        type = types.path;
      };
      when = mkOption {
        description = "Events which trigger a rewrite (create, copy)";
        type = types.listOf (types.str);
      };
      properties = mkOption {
        description = "Additional properties";
        type = types.attrs;
        default = {};
      };
    };
  };

  toYAML = name: data: pkgs.writeText name (generators.toYAML {} data);

  cfg = config.lxd.image;
  templates =
    if cfg.templates != {}
    then let
      list =
        mapAttrsToList (name: value: {inherit name;} // value)
        (filterAttrs (name: value: value.enable) cfg.templates);
    in {
      files =
        map (tpl: {
          source = tpl.template;
          target = "/templates/${tpl.name}.tpl";
        })
        list;
      properties = listToAttrs (map (tpl:
        nameValuePair tpl.target {
          when = tpl.when;
          template = "${tpl.name}.tpl";
          properties = tpl.properties;
        })
      list);
    }
    else {
      files = [];
      properties = {};
    };
in {
  options = {
    lxd.image = {
      templates = mkOption {
        description = "Templates for LXD";
        type = types.attrsOf (types.submodule templateSubmodule);
        default = {};
        example = literalExpression ''
          {
            # create /etc/hostname on container creation
            "hostname" = {
              enable = true;
              target = "/etc/hostname";
              template = builtins.writeFile "hostname.tpl" "{{ container.name }}";
              when = [ "create" ];
            };
            # create /etc/nixos/hostname.nix with a configuration for keeping the hostname applied
            "hostname-nix" = {
              enable = true;
              target = "/etc/nixos/hostname.nix";
              template = builtins.writeFile "hostname-nix.tpl" "{ ... }: { networking.hostName = "{{ container.name }}"; }";
              # copy keeps the file updated when the container is changed
              when = [ "create" "copy" ];
            };
            # copy allow the user to specify a custom configuration.nix
            "configuration-nix" = {
              enable = true;
              target = "/etc/nixos/configuration.nix";
              template = builtins.writeFile "configuration-nix" "{{ config_get(\"user.user-data\", properties.default) }}";
              when = [ "create" ];
            };
          };
        '';
      };
    };
  };

  config = {
    system.build.metadata = pkgs.callPackage (modulesPath + "/../lib/make-system-tarball.nix") {
      fileName = "nixos-lxd-metadata-${pkgs.stdenv.hostPlatform.system}";
      contents =
        [
          {
            source = toYAML "metadata.yaml" {
              architecture = builtins.elemAt (builtins.match "^([a-z0-9_]+).+" (toString pkgs.system)) 0;
              creation_date = 1;
              properties = {
                description = "NixOS ${config.system.nixos.codeName} ${config.system.nixos.label} ${pkgs.system}";
                os = "nixos";
                release = "${config.system.nixos.label}";
              };
              templates = templates.properties;
            };
            target = "/metadata.yaml";
          }
        ]
        ++ templates.files;
    };
  };
}
