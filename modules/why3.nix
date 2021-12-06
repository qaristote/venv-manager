{ lib, ... }:

let
  cfg = config.why3;
  why3Flags = concatStringsSep " " ([ ("-C '${cfg.configFile}'") ]);
in {
  options.why3 = {
    enable = lib.mkEnableOption "why3";
    configFile = lib.mkOption {
      type = lib.types.path;
      default = ~/.why3.conf;
      defaultText = literalExample "~/.why3.conf";
      description = ''
        The path to the why3 config file.
      '';
    };
  };
}
