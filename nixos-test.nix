# Debug like this:
# $ nix build .\#checks.x86_64-linux.nixos-test.driver
# $ ./result/bin/nixos-test-driver --interactive
# >>> start_all()
# >>> machine.shell_interact()
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
in
  makeTest {
    name = testName;

    nodes.machine = {...}: {
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
      def instance_is_up(_) -> bool:
        status, _ = machine.execute("lxc exec ${runName} --disable-stdin --force-interactive true")
        return status == 0

      start_all()
      machine.wait_for_unit("lxd.service")

      machine.succeed("lxd init --minimal")
      machine.succeed("${importerBin}")
      machine.succeed("${launchCommand}")
      machine.sleep(2)

      with machine.nested("Waiting for instance to start and lxd-agent to be online"):
        retry(instance_is_up)
    '';
  } {
    inherit pkgs;
    inherit (pkgs) system;
  }
