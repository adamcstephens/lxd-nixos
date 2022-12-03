{
  acl,
  buildGoModule,
  dqlite,
  fetchurl,
  hwdata,
  installShellFiles,
  lib,
  libcap,
  lxc,
  pkg-config,
  raft-canonical,
  sqlite-replication,
  udev,
}: let
  generic = {
    hash,
    version,
  }: let
    src = fetchurl {
      inherit hash;

      urls = [
        "https://linuxcontainers.org/downloads/lxd/lxd-${version}.tar.gz"
        "https://github.com/lxc/lxd/releases/download/lxd-${version}/lxd-${version}.tar.gz"
      ];
    };
  in
    buildGoModule rec {
      pname = "lxd-unwrapped";
      inherit src version;

      vendorSha256 = null;

      postPatch = ''
        substituteInPlace shared/usbid/load.go \
          --replace "/usr/share/misc/usb.ids" "${hwdata}/share/hwdata/usb.ids"
      '';

      excludedPackages = ["test" "lxd/db/generate"];

      nativeBuildInputs = [installShellFiles pkg-config];
      buildInputs = [
        lxc
        acl
        libcap
        dqlite.dev
        raft-canonical.dev
        sqlite-replication
        udev.dev
      ];

      ldflags = ["-s" "-w"];
      tags = ["libsqlite3"];

      preBuild = ''
        # required for go-dqlite. See: https://github.com/lxc/lxd/pull/8939
        export CGO_LDFLAGS_ALLOW="(-Wl,-wrap,pthread_create)|(-Wl,-z,now)"
      '';

      preCheck = let
        skippedTests = [
          "TestValidateConfig"
          "TestConvertNetworkConfig"
          "TestConvertStorageConfig"
          "TestSnapshotCommon"
          "TestContainerTestSuite"
        ];
      in ''
        # Disable tests requiring local operations
        buildFlagsArray+=("-run" "[^(${
          builtins.concatStringsSep "|" skippedTests
        })]")
      '';

      postInstall = ''
        installShellCompletion --bash --name lxd ./scripts/bash/lxd-client
      '';

      meta = with lib; {
        description = "Daemon based on liblxc offering a REST API to manage containers";
        homepage = "https://linuxcontainers.org/lxd/";
        changelog = "https://github.com/lxc/lxd/releases/tag/lxd-${version}";
        license = licenses.asl20;
        maintainers = with maintainers; [marsam ifd3f];
        platforms = platforms.linux;
      };
    };
in rec {
  lxd-unwrapped-5_0 = generic {
    version = "5.0.1";
    hash = "sha256-Y74OwgbaaRQlEnHSd4EkJCAp49PAv0qiOB2SHuATM4I=";
  };

  lxd-unwrapped-5_7 = generic {
    version = "5.7";
    hash = "sha256-TZeF/VPrP4qRAVezJwQWtfypsxBJpnTrST0uDdw3WVI=";
  };

  lxd-unwrapped-5_8 = generic {
    version = "5.8";
    hash = "sha256-mYyDYO8k4MVoNa8xfp1vH2nyuhNsDJ93s9F5hjaMftk=";
  };

  lxd-unwrapped-latest = lxd-unwrapped-5_7;
  lxd-unwrapped = lxd-unwrapped-5_0;
}
