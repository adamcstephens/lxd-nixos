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
  lxd ? pkgs.lxd,
  type ? "container",
}: let
  runName = "test-lxd-image";
  launchCommand =
    "lxc launch ${image} ${runName} --profile default "
    + (
      if type == "virtual-machine"
      then "--vm --config security.secureboot=false"
      else ""
    );
  sleep =
    if type == "virtual-machine"
    then "60"
    else "10";
in
  makeTest {
    name = testName;

    nodes.server = {...}: {
      boot.kernelModules = ["vhost_vsock"];

      virtualisation.cores = 2;
      virtualisation.memorySize = 2048;
      virtualisation.diskSize = 4096;

      virtualisation.lxd = {
        enable = true;
        package = lxd;
      };
    };

    testScript = ''
      start_all()
      server.wait_for_unit("lxd.service")
      server.succeed("lxd init --minimal")
      server.succeed("${importerBin}")
      server.succeed("lxc image list -f compact")
      server.succeed("${launchCommand}")
      server.succeed("sleep ${sleep}")
      server.succeed("lxc list -f compact")
      server.succeed("lxc exec ${runName} --force-interactive true")
    '';
  } {
    inherit pkgs;
    inherit (pkgs) system;
  }
