{ config, lib, pkgs, ... }:

with lib;
let cfg = config.golang;
in {
  options.golang = {
    enable = mkEnableOption { name = "golang"; };
    package = mkOption {
      type = types.package;
      default = pkgs.go;
      defaultText = literalExample "pkgs.go";
      description = ''
        The package for Go. This sets the version of Go..
      '';
      example = literalExample "pkgs.go_1_15";
    };
  };

  config = mkIf cfg.enable {
    buildInputs = [ cfg.package ] ++ (with pkgs; [ gocode gofumpt golint ]);
  };
}
