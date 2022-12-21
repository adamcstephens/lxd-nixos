{stdenv, ...}:
stdenv.mkDerivation {
  pname = "ovmf";
  version = "0.1.0-lxd5.7";
  src = ./.;
  dontBuild = true;

  outputs = ["out" "fd"];

  installPhase = ''
    mkdir $out
    mkdir -p $fd/FV
    cp OVMF* $fd/FV/
  '';
}
