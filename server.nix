{
  inputs,
  self,
  withSystem,
  ...
}: {
  flake.nixosConfigurations.test = withSystem "x86_64-linux" ({system, ...}:
    inputs.nixpkgs.lib.nixosSystem {
      system = system;
      modules = [
        self.nixosModules.server
        {
          virtualisation.lxd = {
            preseed = {
              networks = [
                {
                  name = "lxd-my-bridge";
                  type = "bridge";
                  config = {
                    "ipv4.address" = "none";
                    "ipv6.address" = "none";
                  };
                }
              ];
              profiles = [
                {
                  name = "testprofile";
                  config = {
                    myconfig = "true";
                    "boot.autostart" = "false";
                  };
                  # devices = {
                  #   testdevice = {
                  #     # name = "td";
                  #     gpu = "true";
                  #   };
                  # };
                }
              ];
            };
          };
        }
      ];
    });
}
