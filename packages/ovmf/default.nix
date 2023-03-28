{stdenv, ...}:
stdenv.mkDerivation {
  pname = "ovmf";
  version = "0.1.1-lxd5.12";
  src = ./.;
  dontBuild = true;

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
