{
  stdenv,
  squashfsTools,
  closureInfo,
  fileName ? "squashfs",
  # The root directory of the squashfs filesystem is filled with the
  # closures of the Nix store paths listed here.
  storeContents ? [],
  # Pseudo files to be added to squashfs image
  pseudoFiles ? [],
  # Compression parameters.
  # For zstd compression you can use "zstd -Xcompression-level 6".
  comp ? "zstd",
}: let
  pseudoFilesArgs = builtins.toString (builtins.map (v: ''-p "${v}"'') pseudoFiles);
in
  stdenv.mkDerivation {
    name = "${fileName}.img";

    nativeBuildInputs = [squashfsTools];

    buildCommand = ''
      set -x
      closureInfo=${closureInfo {rootPaths = storeContents;}}

      # Also include a manifest of the closures in a format suitable
      # for nix-store --load-db.
      cp $closureInfo/registration nix-path-registration

      # 64 cores on i686 does not work
      # fails with FATAL ERROR: mangle2:: xz compress failed with error code 5
      if ((NIX_BUILD_CORES > 48)); then
        NIX_BUILD_CORES=48
      fi

      # Generate the squashfs image.
      mksquashfs nix-path-registration $(cat $closureInfo/store-paths) $out ${pseudoFilesArgs}  \
        -no-hardlinks -no-strip -all-root -root-mode 0755 -b 1048576 -comp ${comp} \
        -processors $NIX_BUILD_CORES
    '';
  }
