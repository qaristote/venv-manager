{ config, lib, pkgs, ... }:

with lib;
with builtins;
let cfg = config.rust;
in {
  options.rust = {
    enable = mkEnableOption { name = "rust"; };
    packages = mkOption {
      type = types.lazyAttrsOf types.package;
      default = pkgs.rust.packages.stable;
      defaultText = literalExample "pkgs.rust.packages.stable";
      description = ''
        The set of Rust packages from which to get the toolchain.
      '';
    };
  };

  config = mkIf cfg.enable {
    nativeBuildInputs = with cfg.packages; [ rustc cargo pkgs.gcc ];
    buildInputs = with cfg.packages; [ rustfmt clippy ];

    envVars = {
      RUST_SRC_PATH = {
        value = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
      };
    };
  };
}
