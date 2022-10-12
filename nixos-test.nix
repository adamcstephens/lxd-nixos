# Debug like this:
# $ nix build .\#checks.x86_64-linux.nixos-test.driver
# $ ./result/bin/nixos-test-driver --interactive
# >>> start_all()
# >>> server.shell_interact()
{
  image,
  importerBin,
  makeTest,
  pkgs,
  testName,
  vm ? false,
}: let
  runName = "test-lxd-image";
  launchCommand =
    "lxc launch ${image} ${runName} --profile default --ephemeral"
    + (
      if vm
      then " --vm --config security.secureboot=false"
      else ""
    );
in
  makeTest {
    name = testName;

    nodes.server = {...}: {
      virtualisation.cores = 2;
      virtualisation.memorySize = 2046;
      virtualisation.diskSize = 4096;

      virtualisation.lxd = {
        enable = true;
      };

      # boot.kernelModules
    };

    testScript = ''
      start_all()
      server.wait_for_unit("lxd.service")
      server.succeed("lxd init --minimal")
      server.succeed("${importerBin}")
      server.succeed("${launchCommand}")
      server.succeed("sleep 10")
      server.console_interact()
      # server.wait_until_succeeds("lxc exec ${runName} -- ping -c 1 1.1.1.1")
    '';
  } {
    inherit pkgs;
    inherit (pkgs) system;
  }
