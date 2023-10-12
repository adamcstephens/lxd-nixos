{
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}: {
  config = {
    # explicitly set /run to shared so bind mounts work, e.g. LoadCredential=
    boot.specialFileSystems = {
      "/run".options = ["shared"];
    };
  };
}
