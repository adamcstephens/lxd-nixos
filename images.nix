{inputs, ...}: let
  commonConfig = {
    networking.hostName = "";
    lxd.image.templates = {
      "hostname" = {
        enable = true;
        target = "/etc/hostname";
        template = builtins.toFile "hostname.tpl" "{{ instance.name }}";
        when = ["start"];
      };
    };
  };
in {
  config.lxd.images = {
    #
    # 22.11
    #
    container-2211-x86_64 = {
      release = "22.11";
      nixpkgs = inputs.nixpkgs;

      system = "x86_64-linux";
      type = "container";

      config = commonConfig;
    };

    virtual-machine-2211-x86_64 = {
      release = "22.11";
      nixpkgs = inputs.nixpkgs;

      system = "x86_64-linux";
      type = "virtual-machine";

      config = commonConfig;
    };

    container-2211-aarch64 = {
      release = "22.11";
      nixpkgs = inputs.nixpkgs;

      system = "aarch64-linux";
      type = "container";

      config = commonConfig;
    };

    virtual-machine-2211-aarch64 = {
      release = "22.11";
      nixpkgs = inputs.nixpkgs;

      system = "aarch64-linux";
      type = "virtual-machine";

      config = commonConfig;
    };

    #
    # unstable
    #
    container-unstable-x86_64 = {
      release = "unstable";
      nixpkgs = inputs.nixpkgs-unstable;

      system = "x86_64-linux";
      type = "container";

      config = commonConfig;
    };

    virtual-machine-unstable-x86_64 = {
      release = "unstable";
      nixpkgs = inputs.nixpkgs-unstable;

      system = "x86_64-linux";
      type = "virtual-machine";

      config = commonConfig;
    };

    container-unstable-aarch64 = {
      release = "unstable";
      nixpkgs = inputs.nixpkgs-unstable;

      system = "aarch64-linux";
      type = "container";

      config = commonConfig;
    };

    virtual-machine-unstable-aarch64 = {
      release = "unstable";
      nixpkgs = inputs.nixpkgs-unstable;

      system = "aarch64-linux";
      type = "virtual-machine";

      config = commonConfig;
    };
  };
}
