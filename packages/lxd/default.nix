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
  sqlite,
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

      outputs = ["out" "client"];

      postPatch = ''
        substituteInPlace shared/usbid/load.go \
          --replace "/usr/share/misc/usb.ids" "${hwdata}/share/hwdata/usb.ids"
      '';

      excludedPackages = ["test" "lxd/db/generate" "lxd-agent" "lxd-migrate"];

      strictDeps = true;
      nativeBuildInputs = [installShellFiles pkg-config];
      buildInputs = [
        lxc
        acl
        libcap
        dqlite.dev
        raft-canonical.dev
        sqlite
        udev.dev
      ];

      ldflags = ["-s" "-w"];
      tags = ["libsqlite3"];

      preBuild = ''
        # required for go-dqlite. See: https://github.com/lxc/lxd/pull/8939
        export CGO_LDFLAGS_ALLOW="(-Wl,-wrap,pthread_create)|(-Wl,-z,now)"
      '';

      postBuild = ''
        CGO_ENABLED=0 go install -v -tags netgo ./lxd-migrate
        CGO_ENABLED=0 go install -v -tags agent,netgo ./lxd-agent
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

      preInstall = ''
        mkdir -p $client/bin
        mv "$GOPATH/bin/lxc" $client/bin
      '';

      postInstall = ''
        installShellCompletion --bash --name lxd ./scripts/bash/lxd-client
      '';

      meta = with lib; {
        description = "Daemon based on liblxc offering a REST API to manage containers";
        homepage = "https://linuxcontainers.org/lxd/";
        changelog = "https://github.com/lxc/lxd/releases/tag/lxd-${version}";
        license = licenses.asl20;
        maintainers = with maintainers; [marsam adamcstephens];
        platforms = platforms.linux;
      };
    };
in rec {
  lxd-unwrapped_5_0 = generic {
    version = "5.0.2";
    hash = "sha256-gJ0+rIbZzDJ0GcQSH45r1f+qnkikXz3mGPZYKgzEzjo=";
  };

  lxd-unwrapped_5_11 = generic {
    version = "5.12";
    hash = "sha256-YGH/M0aw56snNt3s8drcJYHZPYkVW993YilF228nMhw=";
  };

  lxd-unwrapped = lxd-unwrapped_5_11;
  lxd-unwrapped-lts = lxd-unwrapped_5_0;
}
