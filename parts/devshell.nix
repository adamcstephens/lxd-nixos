{...}: {
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShellNoCC {
      buildInputs = [
        pkgs.cachix
        pkgs.just
      ];
    };
  };
}
