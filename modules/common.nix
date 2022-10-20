{lib, ...}: {
  imports = [
    ./image-metadata.nix
  ];
  networking.useDHCP = lib.mkDefault true;

  documentation.nixos.enable = lib.mkDefault false;
  documentation.enable = lib.mkDefault false;
  programs.command-not-found.enable = lib.mkDefault false;

  services.openssh.enable = lib.mkDefault true;
}
