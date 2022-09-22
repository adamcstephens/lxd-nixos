{
  stdenv,
  lxd-image,
}:
stdenv.mkDerivation {
  name = "lxd-image";

  # modules = [
  #   lxd-image.nixosModules.lxd-image
  # ];
}
