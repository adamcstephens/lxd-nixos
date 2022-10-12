# Debug like this:
# $ nix build .\#checks.x86_64-linux.nixos-test.driver
# $ ./result/bin/nixos-test-driver --interactive
# >>> start_all()
# >>> server.shell_interact()
{
  importer,
  makeTest,
  pkgs,
  testName ? "nixos-test",
  release ? "unstable",
  vm ? false,
}: let
  launchCommand =
    "lxc launch nixos/${release} test-lxd-image --profile default --ephemeral"
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
    };

    testScript = ''
      start_all()
      server.wait_for_unit("lxd.service")
      server.succeed("lxd init --minimal")
      server.succeed("${importer}/bin/import-image")
      server.succeed("${launchCommand}")
      server.succeed("sleep 5")
      server.wait_until_succeeds("lxc exec test-lxd-image true")
    '';
  } {
    inherit pkgs;
    inherit (pkgs) system;
  }
