{
  config,
  inputs,
  ...
}: {
  config.lxd.images = {
    #
    # 22.11
    #
    container-2211-x86_64 = {
      release = "22.11";
      nixpkgs = inputs.nixpkgs;

      system = "x86_64-linux";
      type = "container";

      config = config.lxd.imageDefaults.config;
    };

    virtual-machine-2211-x86_64 = {
      release = "22.11";
      nixpkgs = inputs.nixpkgs;

      system = "x86_64-linux";
      type = "virtual-machine";

      config = config.lxd.imageDefaults.config;
    };

    container-2211-aarch64 = {
      release = "22.11";
      nixpkgs = inputs.nixpkgs;

      system = "aarch64-linux";
      type = "container";

      config = config.lxd.imageDefaults.config;
    };

    virtual-machine-2211-aarch64 = {
      release = "22.11";
      nixpkgs = inputs.nixpkgs;

      system = "aarch64-linux";
      type = "virtual-machine";

      config = config.lxd.imageDefaults.config;
    };

    #
    # unstable
    #
    container-unstable-x86_64 = {
      release = "unstable";
      nixpkgs = inputs.nixpkgs-unstable;

      system = "x86_64-linux";
      type = "container";

      config = config.lxd.imageDefaults.config;
    };

    virtual-machine-unstable-x86_64 = {
      release = "unstable";
      nixpkgs = inputs.nixpkgs-unstable;

      system = "x86_64-linux";
      type = "virtual-machine";

      config = config.lxd.imageDefaults.config;
    };

    container-unstable-aarch64 = {
      release = "unstable";
      nixpkgs = inputs.nixpkgs-unstable;

      system = "aarch64-linux";
      type = "container";

      config = config.lxd.imageDefaults.config;
    };

    virtual-machine-unstable-aarch64 = {
      release = "unstable";
      nixpkgs = inputs.nixpkgs-unstable;

      system = "aarch64-linux";
      type = "virtual-machine";

      config = config.lxd.imageDefaults.config;
    };
  };
}
