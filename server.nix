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
              profiles = [
                {
                  name = "testprofile";
                  devices = {
                    testdevice = {
                      # name = "td";
                      gpu = "true";
                    };
                  };
                }
              ];
            };
          };
        }
      ];
    });
}
