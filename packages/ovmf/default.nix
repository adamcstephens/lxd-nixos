{stdenv, ...}:
stdenv.mkDerivation {
  pname = "ovmf";
  version = "0.2.0-lxd5.15";
  src = ./.;

  dontPatch = true;
  dontBuild = true;
  dontConfigure = true;
  dontFixup = true;

  outputs = ["out" "fd"];

  installPhase =
    ''
      mkdir $out
      mkdir -p $fd/FV
    ''
    + (
      if stdenv.hostPlatform.isx86
      then ''
        cp x86_64/OVMF* $fd/FV/
      ''
      else ''
        cp aarch64/OVMF* $fd/FV/
      ''
    );
}
